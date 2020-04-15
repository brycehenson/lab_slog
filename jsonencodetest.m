

a=[];
a.b=1;
a.c.d='D:\Dropbox\UNI\projects\programs\SLOGS_structured_logging_standard';

str_version=jsonencode(a)
recovereda=jsondecode(str_version)
recovereda.c.d