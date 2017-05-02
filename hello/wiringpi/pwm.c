/*
 * pwm.c:
 *	This tests the hardware PWM channel.
 *
 * Copyright (c) 2012-2013 Gordon Henderson. <projects@drogon.net>
 ***********************************************************************
 * This file is part of wiringPi:
 *	https://projects.drogon.net/raspberry-pi/wiringpi/
 *
 *    wiringPi is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU Lesser General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    wiringPi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public License
 *    along with wiringPi.  If not, see <http://www.gnu.org/licenses/>.
 ***********************************************************************
 */

#include <wiringPi.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

// PWM0 = GPIO18 = WiringPi pin 1
#define PWM_PIN 1
#define COUNT   1024
#define LOOPS   5

int main (int argc, char *argv[]) {
    int i,bright;
    printf ("Raspberry Pi wiringPi PWM test program\n") ;

    // Check if we have root access.. otherwise system will crash!
    if (getuid()) {
        printf("\nError: WiringPi Library requires root.\nPlease run as 'sudo %s'.\n\n", argv[0]);
        return 0;
    }

    // Init WiringPi
    if (wiringPiSetup () == -1)
        exit (1) ;

    // Set PWM output
    pinMode (PWM_PIN, PWM_OUTPUT) ;

    // Fade pin
    for (i = 1 ; i <= LOOPS ; ++i) {

        // Increase intensity
        for (bright = 0 ; bright < COUNT ; ++bright) {
            printf("\rIteration: %2d/%2d - Brightness: %4d/%4d", i, LOOPS, bright, COUNT);
            pwmWrite (PWM_PIN, bright) ;
            delay (1) ;
        }

        // Decrease intensity
        for (bright = COUNT ; bright >= 0 ; --bright) {
            printf("\rIteration: %2d/%2d - Brightness: %4d/%4d", i, LOOPS, bright, COUNT);
            pwmWrite (PWM_PIN, bright) ;
            delay (1) ;
        }

    }

    // Newline for pretty-printing
    printf("\nDone\n");

    return 0 ;
}
