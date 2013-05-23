#!/bin/bash

convert "$1" txt: | sed -e 's/.*#//; s/ .*//'