from math import *
clockFrequency = 203e6;
pwmLevels = 16;
def microsToClock(us): return int(floor(0.5+1.0e-6*us*clockFrequency));

print microsToClock(63.5-1.5)//pwmLevels-(microsToClock(6.2+4.7)+pwmLevels-1)//pwmLevels;
