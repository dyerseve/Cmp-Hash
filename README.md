# Cmp-Hash
 
The idea of this script is to prompt for two files and then compare them based on two calculations, the checksum of the first n bytes and the last n bytes


For files smaller than (n*2) bytes, this is a waste of cpu cycles, you can just compare them straight up with any checksum tool and it will run faster.


For files larger than (n*2) bytes, first a warning, this should not be used for critical functions, we are not testing the entire file, we are sampling the file and running a checksum on the samples


The idea is if you set $ByteSize = 10000000, we read the first 10MB and the last 10MB of the file and compute a checksum, we then do that on the second file and compare.
If they match we have a reasonable certainty that the files are the same, without waiting for a long checksum function to complete.


Is it a certainty that the files match? NO!


Do not use this on an untrusted file, this is for checking for human error such as terminating a copy before it's complete, copying the wrong file, etc.
