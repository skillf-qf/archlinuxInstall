#!/bin/bash

if ls /sys/firmware/efi/efivar > /dev/null; then
	echo "right"
else
	echo "error"
fi
