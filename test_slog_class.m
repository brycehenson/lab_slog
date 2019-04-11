fclose('all');
%%test slog class
a=slog_class;
a.teir='model';
a.log_dir='./test/';
a.open_log(true);
%a.log_time %optional
%a.teir='model';%test that error is not returned when an error is not returned
a.level='ERROR';
a.operation='writing out somenumbers';
a.parameters.thing_1=linspace(5,3,1e2);
a.parameters.thing_2=rand(1,10);
a.write_log;
a.close_log;