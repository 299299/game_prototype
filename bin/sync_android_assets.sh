#!/usr/bin/env bash

rm -rf ~/StudioProjects/build_android/app/src/main/assets/MyData/;
cp -rf MyData ~/StudioProjects/build_android/app/src/main/assets/

rm -rf ~/StudioProjects/build_android/app/src/main/assets/Data/;
cp -rf TargetData ~/StudioProjects/build_android/app/src/main/assets/Data

rm -rf ~/StudioProjects/build_android/app/src/main/assets/Autoload/;