/* hil_client.c: a host program that owns the simulation clock through Renode's external control API
 * (tools/external_control_client, reworked in Renode 1.17): it steps the BlackPill F411 model in virtual time,
 * watches the LED pin (PC13), drives the KEY pin (PA0) and reads peripheral registers over the system bus,
 * as a hardware-in-the-loop or co-simulation harness would.  Usage: hil_client <port> */
#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "renode_api.h"

static int failures;
#define CHECK(cond, ...) do { printf("%s  ", (cond) ? "ok  " : "FAIL"); printf(__VA_ARGS__); printf("\n"); \
                              if (!(cond)) failures++; } while (0)
#define TRY(call) do { renode_error_t *e_ = (call); if (e_ != NO_ERROR) { \
        fprintf(stderr, "%s failed: %s\n", #call, e_->message ? e_->message : "?"); renode_free_error(e_); exit(1); } } while (0)

static int led_edges;
static void on_led(void *user, renode_gpio_event_data_t *ev)
{
    (void)user; (void)ev;
    led_edges++;
}

int main(int argc, char **argv)
{
    renode_t *renode;
    renode_machine_t *mach;
    renode_gpio_t *portc, *porta;
    renode_bus_context_t *sysbus;
    renode_time_t t0, t1, step;
    uint32_t brr = 0, cr1 = 0;
    bool led;

    if (argc != 2) { fprintf(stderr, "usage: %s <port>\n", argv[0]); return 2; }
    TRY(renode_connect(argv[1], &renode));
    TRY(renode_get_machine(renode, "blackpill", &mach));
    TRY(renode_get_gpio(mach, "sysbus.gpioPortC", &portc));
    TRY(renode_get_gpio(mach, "sysbus.gpioPortA", &porta));
    TRY(renode_get_sysbus(mach, &sysbus));

    /* virtual time advances only when the client says so */
    TRY(renode_get_current_time(renode, &t0));
    TRY(renode_create_time(100, TU_MILLISECONDS, &step));
    TRY(renode_register_gpio_state_change_callback(portc, 13, NULL, on_led));
    for (int i = 0; i < 20; i++)
        TRY(renode_run_for(renode, step));
    TRY(renode_get_current_time(renode, &t1));
    CHECK(renode_time_to_seconds(t1) - renode_time_to_seconds(t0) > 1.999 &&
          renode_time_to_seconds(t1) - renode_time_to_seconds(t0) < 2.001,
          "20 x run_for(100 ms) = %.3f s of virtual time", renode_time_to_seconds(t1) - renode_time_to_seconds(t0));
    CHECK(led_edges >= 4, "LED PC13: %d state-change callbacks in 2 s of virtual time", led_edges);
    TRY(renode_get_gpio_state(portc, 13, &led));
    printf("      LED PC13 is now %s\n", led ? "high" : "low");

    /* registers the firmware programmed, read over the system bus */
    TRY(renode_sysbus_read(sysbus, 0x40011008, AW_DOUBLE_WORD, &brr, 1));
    TRY(renode_sysbus_read(sysbus, 0x4001100C, AW_DOUBLE_WORD, &cr1, 1));
    CHECK(brr == 0x8B, "USART1_BRR = 0x%" PRIx32 " (firmware writes 0x8b)", brr);
    CHECK((cr1 & 0x200C) == 0x200C, "USART1_CR1 = 0x%" PRIx32 " (UE|TE|RE set)", cr1);

    /* drive the KEY input pin; the firmware reports it on the UART (checked by example.sh) */
    TRY(renode_set_gpio_state(porta, 0, false));   /* active low: pressed */
    TRY(renode_run_for(renode, step));
    TRY(renode_run_for(renode, step));
    TRY(renode_set_gpio_state(porta, 0, true));
    TRY(renode_run_for(renode, step));

    TRY(renode_disconnect(&renode));
    printf("%s\n", failures ? "external control API: FAILED" : "external control API: all checks passed");
    return failures ? 1 : 0;
}
