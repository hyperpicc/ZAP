system("perl \$ZAP_HOME/sw/binasm.pl $ARGV[0] \$ZAP_HOME/sw/linker/linker.ld prog.bin");
system("perl \$ZAP_HOME/sw/bin2verilog.pl prog.bin > prog.v");
system("rm -f prog.bin");

