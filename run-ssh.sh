#!/bin/bash

gotty -p 2998 -w bash & ngrok http 2998
