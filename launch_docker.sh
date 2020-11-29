#may need to restart docker on windows if computer has gone to sleep and clock is incorrect
#docker run --rm --privileged alpine hwclock -s
#docker build -t isobuilder .
MSYS_NO_PATHCONV=1 winpty docker run --rm -it -v C:\\repos\\ISOmodel:/home isobuilder