- FAT = File Allocation Table

Contains three components

The boot record
- placed in the logical sector zero of the partition, if the media is devided into partition it comes after the [partition] table
- contains data and code for the media if it is bootable

the FAT

the table contains different data at different offsets depending on version, see https://wiki.osdev.org/FAT

The table can be considered a table of contents


Directories and data

self explanitory

### FAT headers

To make a piece of software FAT compatable we need a few headers 

#TODO