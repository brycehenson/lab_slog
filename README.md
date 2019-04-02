# SLOGS (structured logging standard)
Defining a standard for logging data to a json structure that is usefull in an for a bunch of different uses.



    nowdt=datetime('now','TimeZone','local','Format', 'yyyy-MM-dd HH:mm:SSxxxxx');
    log=[];
    
    log.iso_time=strrep(char(nowdt), ' ', 'T');
    log.posix_time=posixtime(nowdt);
    
    
    nowdt=datetime('now');
    log=[];
    log.posix_time=posixtime(nowdt);
    log.iso_time=datestr(nowdt,'yyyy-mm-ddTHH:MM:SS.FFF');
    log.op='scan transition';
    log.parameters.hyperfine=hyperfine_transision;
    log.parameters.sample_time_posix=time_freq_response(:,1);
    log.parameters.set_freq=time_freq_response(:,2);
    log.parameters.pmt_voltage_mean=time_freq_response(:,3);
    log.parameters.pmt_voltage_std=time_freq_response(:,4);
    
## Resources
- [structured logging](https://stackify.com/what-is-structured-logging-and-why-developers-need-it/)
