<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The design implements a safety aware EV charging state machine and displays its current state over VGA. It starts in IDLE and moves to CONNECTED when a plug is detected. Authorization advances it through AUTH to PRECHARGE, when precharge is ready, it enters CHARGING. A full battery signal moves it to COMPLETE, which remains active until the plug is removed.

Over-voltage, over-current, or over-temperature causes a fault in the connection, authorization, and precharge states. Removing the plug in those states or while charging also causes a fault, an emergency stop causes a fault while charging. The controller holds the FAULT state for about two second at its 25.175 MHz clock rate, it returns to IDLE after that interval if the plug is absent. The top level module uses the controller's state output to render the state name and a charging, completion, or fault indicator on the VGA display.

The eight ui_in inputs are, from bit 0 to bit 7: plug detect, authorization, precharge ready, emergency stop, battery full, over-voltage, over-current, and over-temperature. The controller's other status outputs are not connected to the top level pins.

## How to test

Apply the clock and active low reset, then drive the inputs through the sequence: assert ui_in[0] (plug detect), assert ui_in[1] (authorization), keep authorization asserted for the next transition into precharge, and assert ui_in[2] (precharge ready) to start charging. Assert ui_in[4] to show completion, remove the plug to return to idle. To test faults, assert one of ui_in[5], ui_in[6] or ui_in[7] during connection, authorization, or precharge, or assert ui_in[3] while charging. For a fault to clear back to idle, remove the plug and wait about two second.

Observe the VGA output to check the displayed state and status indicator. The design clock is configured for 25.175 MHz.

## External hardware

Use a TinyVGA PMOD compatible VGA adapter and display connected to the uo_out pins for the video sync and 6 bit RGB signals. Drive the eight control and safety inputs through the TinyTapeout ui_in pins, and provide the clock and active low reset. The design does not connect its charging control outputs to external pins, so it provides state display/logic only and is not a power stage charger interface.
