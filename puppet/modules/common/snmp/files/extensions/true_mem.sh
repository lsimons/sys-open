#!/bin/bash
free | grep ^Mem | sed -e 's/Mem://' | xargs
