#
#       program to parse the export.xml file into csv files for plotting.
#
#
# 20221106 - added InstantaneousBeatsPerMinute
# 20221105 - Name Change
# 20221027 - Initial Version

function ut (unixdate) {
# 20210606 - Initial Version
   # convert linux date (epoch time in seconds) to human readable date
   #          0=12/31/1969 17:00:00
   # 20221005: cmd="awk -f unixtime.awk TIME=" unixdate " /etc/fstab"
   # 20221005: # system(cmd | getline ftime ) ;# bug
   # 20221005: cmd | getline Humanreaddate
   # 20221005: close(cmd)
   Humanreaddate = strftime( "%m/%d/%Y %T", unixdate)
   # Humanreaddate = strftime( "%m/%d/%Y %T %Z", unixdate) ; # with timezone
   return Humanreaddate
   }

function lt (date, time, zone) {
   # convert date and time to ut (unix time 0=12/31/1969 17:00:00)
   # 20211127 - Initial Version
   #
   gsub(/\./,"/",date)
   cmd=" date -d '" date " " time " " zone "' +%s"
   cmd | getline seconds
   close(cmd)
   return seconds
   }

#
# MIN is from msa.awk
#
function MIN(one,two) {
   result=two + 0
   if (one < two ) {
      result= one + 0
      }
   return result
   } # end function1
 
# MAX is from msa.awk
# 
function MAX(one,two) {
   result=two + 0
   if (one > two ) {
      result= one + 0
      }
   return result
   } # end function
#
# STDV does error checking on standard deviation calculation
#
function STDV(xnum, xsum, xsum2) {
   # xnum  is number of values used in calculation
   # xsum  is the sum of the values
   # xsum2 is the sum of the values squared
   if ( xnum == 0 ) { return "DIV by 0" }
   #
   #                    ____________________________________
   #                   /   N                  N         2                 
   #                  /  ______        (    ______    )                   
   #                 /   \             (    \         )                   
   #                /  1  \     2      (  1  \        )                     
   # STDV = \      /  ---  >   X   --- ( ---  >   X   )                          
   #         \    /    N  /     i      (  N  /     i  )                    
   #          \  /       /____         (    /____     )                   
   #           \/         i=1                i=1                          
   #
   underrad = xsum2/xnum - ( (xsum/xnum)*(xsum/xnum) )
   # usually negative numbers is from round off of small stdev.
   if (underrad < 0 ) { underrad = - underrad }
   mu=xsum/xnum          ;# mean
   sigma=sqrt(underrad)  ;# standard deviation
   return sigma
   } ;# end function STDV

BEGIN {
   DEBUG=0
   PROG="apple_health_parse.awk"
   SRtime=strftime("%s") # starttime in seconds
   # TIME=strftime("%c") # similar to date output
   # TIME=strftime("%a %b %d %H:%M:%S %Z %Y") # = date = Fri Jun 22 11:56:11 MST 2007
   TIME=strftime("%a %b %d %H:%M:%S %Y") #        = Fri Jun 22 11:56:11 2007
   # months_list="Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"
   # z=split(months_list,months_param,",")
   # for (i=1; i <= z; ++i){
   #       # print "months_param[" i "]: " months_param[i]
   #       months[months_param[i]] = "";
   #    } # end for
   # testtime=1665033525
   # hrtime=ut(testtime)
   # epochtime=lt("10/05/2022", "22:18:45", "MST")
   # print "testtime = " testtime " === " epochtime " = " hrtime

   # Defaults
   last_type=""
   last_cDdate=""
   DIR="CSV" ; # directory to write csv files to
   Min["StairDescentSpeed"]=1E36
   Max["StairDescentSpeed"]=-1E36
   Min["HeadphoneAudioExposure"]=1E36
   Max["HeadphoneAudioExposure"]=-1E36
   Min["StairAscentSpeed"]=1E36
   Max["StairAscentSpeed"]=-1E36
   Min["FlightsClimbed"]=1E36
   Max["FlightsClimbed"]=-1E36
   Min["SixMinuteWalkTestDistance"]=1E36
   Max["SixMinuteWalkTestDistance"]=-1E36
   Min["AppleExerciseTime"]=1E36
   Max["AppleExerciseTime"]=-1E36
   Min["WalkingHeartRateAverage"]=1E36
   Max["WalkingHeartRateAverage"]=-1E36
   Min["RestingHeartRate"]=1E36
   Max["RestingHeartRate"]=-1E36
   Min["WalkingAsymmetryPercentage"]=1E36
   Max["WalkingAsymmetryPercentage"]=-1E36
   Min["EnvironmentalAudioExposure"]=1E36
   Max["EnvironmentalAudioExposure"]=-1E36
   Min["WalkingDoubleSupportPercentage"]=1E36
   Max["WalkingDoubleSupportPercentage"]=-1E36
   Min["WalkingSpeed"]=1E36
   Max["WalkingSpeed"]=-1E36
   Min["WalkingStepLength"]=1E36
   Max["WalkingStepLength"]=-1E36
   Min["IrregularHeartRhythmEvent"]=1E36
   Max["IrregularHeartRhythmEvent"]=-1E36
   Min["SleepAnalysis"]=1E36
   Max["SleepAnalysis"]=-1E36
   Min["OxygenSaturation"]=1E36
   Max["OxygenSaturation"]=-1E36
   Min["RespiratoryRate"]=1E36
   Max["RespiratoryRate"]=-1E36
   Min["AppleStandHour"]=1E36
   Max["AppleStandHour"]=-1E36
   Min["AppleStandTime"]=1E36
   Max["AppleStandTime"]=-1E36
   Min["HeartRateVariabilitySDNN"]=1E36
   Max["HeartRateVariabilitySDNN"]=-1E36
   Min["StepCount"]=1E36
   Max["StepCount"]=-1E36
   Min["DistanceWalkingRunning"]=1E36
   Max["DistanceWalkingRunning"]=-1E36
   Min["BasalEnergyBurned"]=1E36
   Max["BasalEnergyBurned"]=-1E36
   Min["HeartRate"]=1E36
   Max["HeartRate"]=-1E36
   Min["ActiveEnergyBurned"]=1E36
   Max["ActiveEnergyBurned"]=-1E36
   Min["Q"]=1E36
   Max["Q"]=-1E36
   }

(last_file != FILENAME) {
   filen=FILENAME
   DIR=FILENAME
   sub("/export.xml","",DIR)
   FIL=substr(FILENAME,ld+1)
   print  "FILENAME [" FILENAME "]\t DIR [" DIR "]"
   # sub(/\.csv/,"",filen)
   last_file=FILENAME
   if (DEBUG) {
      print "FILENAME [" FILENAME "]\t filen [" filen "]"
      }
   }

#<HealthData locale="en_US">
/<HealthData / {
   HDfound = 1
   }
#</HealthData>
/<\/HealthData/ {
   HDfound = 0
   }

# <Record type="HKCategoryTypeIdentifierMindfulSession" sourceName="David’s Apple Watch" sourceVersion="8.7" creationDate="2022-07-31 09:21:49 -0700" startDate="2022-07-31 09:20:46 -0700" endDate="2022-07-31 09:21:46 -0700"/>
#<ActivitySummary dateComponents="2022-04-27" activeEnergyBurned="0" activeEnergyBurnedGoal="0" activeEnergyBurnedUnit="Cal" appleMoveTime="0" appleMoveTimeGoal="0" appleExerciseTime="0" appleExerciseTimeGoal="30" appleStandHours="0" appleStandHoursGoal="12"/>
/<Record type="HKCategoryTypeIdentifierMindfulSession" / ||
/<ActivitySummary / { next } ; # skip

#   <InstantaneousBeatsPerMinute bpm="71" time="10:13:58.26 PM"/>
/<InstantaneousBeatsPerMinute/ &&
(HDfound == 1) {
   itype="InstantaneousBeatsPerMinute"
   icnt++
   if (icnt == 1) {
      iofile=DIR "/" itype ".csv"
      print "Now: '" itype "'  writing to '" iofile "'"
      print "" > iofile
      }
   bpm=$2
   sub("bpm=\"","",bpm)
   sub("\"","",bpm)
   bpm=bpm+0
   itime=$NF
   sub("time=\"","",itime)
   sub("\"/>","",itime)
   if (icnt == 1) {
      istart= cDdate " " itime
      }
   else {
      istop = cDdate " " itime
      }
   print cDdate " " itime ", " bpm >> iofile
   }

#                                                                                                                                                                                                                                                            NF-8             NF-9                NF-8     NF-7     NF-6                NF-5     NF-4   NF-3                NF-2     NF-1    NF    
#                   1      2                                                        3                 4      5                  6                7                   6               9       10                  11           12            13                   14                   15                  16       17       18                  19       20     21                  22       23
# first record: <Record type="HKCategoryTypeIdentifierIrregularHeartRhythmEvent" sourceName="David’s Apple Watch" sourceVersion="8.7" device="&lt;&lt;HKDevice: 0x281203070&gt;, name:Apple Watch, manufacturer:Apple Inc., model:Watch, hardware:Watch6,7, software:8.7&gt;" creationDate="2022-09-06 11:02:31 -0700" startDate="2022-09-06 11:02:28 -0700" endDate="2022-09-06 11:02:28 -0700">
#  next record:  <MetadataEntry key="HKAlgorithmVersion" value="2"/>
#  last record: <Record type="HKCategoryTypeIdentifierIrregularHeartRhythmEvent" sourceName="David’s Apple Watch" sourceVersion="9.0.2" device="&lt;&lt;HKDevice: 0x2812015e0&gt;, name:Apple Watch, manufacturer:Apple Inc., model:Watch, hardware:Watch6,15, software:9.0.2&gt;" creationDate="2022-10-14 22:13:59 -0700" startDate="2022-10-14 22:13:58 -0700" endDate="2022-10-14 22:13:58 -0700">
#  next record:  <MetadataEntry key="HKAlgorithmVersion" value="2"/>
/<Record type="HKCategoryTypeIdentifierIrregularHeartRhythmEvent"/ &&
(HDfound == 1) {
   # in Health Data
   type=$2
   sub("type=\"HKQuantityTypeIdentifier","",type)
   sub("type=\"HKCategoryTypeIdentifier","",type)
   sub("type=\"HKDataType","",type)
   sub("\"","",type)
   if ( last_type != type ) {
      # open file when writing to csv files
      cnt_file++
      if (cnt_file != 1 ) { close(ofile) }
      ofile=DIR "/" type ".csv"
      Types[type]+1
      print "Now: '" type "' was '" last_type "' writing to '" ofile "'"
      print "" > ofile
      }
   last_type=type
#   unit=$(NF-10) ; # NONE LISTED
#   sub("unit=\"","",unit)
#   sub("\"","",unit)
   # Using creationDate for all plotting.
   creationDate=$(NF-8) " " $(NF-7)
   sub("creationDate=\"","",creationDate)
   sub("\"","",creationDate)
   # creationDate=~"2022-08-19 23:20:49"
   cDdate=substr(creationDate,1,10)
   cDtime=substr(creationDate,12)
   # cDepoch=lt(cDdate,cDtime,"MST") ;# you sorry people in DST figure it out yourself
   last_cDdate=cDdate
   startDate=$(NF-5) " " $(NF-4)
   sub("startDate=\"","",startDate)
   sub("\"","",startDate)
   endDate=$(NF-2) " " $(NF-1)
   sub("endDate=\"","",endDate)
   sub("\"","",endDate)
   getline
   value=$NF
   sub("value=\"","",value)
   sub("\"/>","",value)
   sub("\">","",value)
   value=value+0   ; # make a number (This will make null values zero)
   # stats for each date
   t_d=type "_" cDdate
   N[t_d]++
   Min[t_d]=MIN( Min[t_d], value)
   Max[t_d]=MAX( Max[t_d], value)
   sumX[t_d]=sumX[t_d]+value
   sumX2[t_d]=sumX2[t_d]+(value*value)
#  if (last_cDdate != cDdate ) {
#     cnt_cD_file++
#     if (cnt_file != 1 ) { close(ocDfile) }
#     ofile=DIR "/" type ".csv"
#     NcD[type]++
#     }
   if(DEBUG) {
      print ""
      print "NR = " NR " ; NF = " NF
      print "type '" type "'"
      print "creationDate '" creationDate "'"
      print "startDate '" startDate "'"
      print "endDate '" endDate "'"
      print "value '" value "' unit '" unit "'"
      }
   # print cDepoch ", " creationDate ", " value >> ofile
   print  creationDate ", " value >> ofile
   next
   }

#                                                                                                             NF-8             NF-9                NF-8     NF-7     NF-6                NF-5     NF-4   NF-3                NF-2     NF-1    NF
#                   1      2                                      3                 4         5                  6                7                   6        9       10                  11       12     13                  14       15    16
# first Record:  <Record type="HKQuantityTypeIdentifierHeight" sourceName="AZdave iPhone" sourceVersion="15.5" unit="ft" creationDate="2022-06-28 19:29:06 -0700" startDate="2022-06-28 19:29:06 -0700" endDate="2022-06-28 19:29:06 -0700" value="6"/>
#  last Record:  <Record type="HKQuantityTypeIdentifierHeartRateVariabilitySDNN" sourceName="David’s Apple Watch" sourceVersion="9.0.2" device="&lt;&lt;HKDevice: 0x2812fa440&gt;, name:Apple Watch, manufacturer:Apple Inc., model:Watch, hardware:Watch6,15, software:9.0.2&gt;" unit="ms" creationDate="2022-10-14 22:13:59 -0700" startDate="2022-10-14 22:12:58 -0700" endDate="2022-10-14 22:13:58 -0700" value="137.857">
(NF >= 10) &&
(HDfound == 1) {
   # in Health Data
   type=$2
   sub("type=\"HKQuantityTypeIdentifier","",type)
   sub("type=\"HKCategoryTypeIdentifier","",type)
   sub("type=\"HKDataType","",type)
   sub("\"","",type)
   if ( last_type != type ) {
      # open file when writing to csv files
      cnt_file++
      if (cnt_file != 1 ) { close(ofile) }
      ofile=DIR "/" type ".csv"
      Types[type]+1
      print "Now: '" type "' was '" last_type "' writing to '" ofile "'"
      print "" > ofile
      }
   last_type=type
   unit=$(NF-10)
   sub("unit=\"","",unit)
   sub("\"","",unit)
   # Using creationDate for all plotting.
   creationDate=$(NF-9) " " $(NF-8)
   sub("creationDate=\"","",creationDate)
   sub("\"","",creationDate)
   # creationDate=~"2022-08-19 23:20:49"
   cDdate=substr(creationDate,1,10)
   cDtime=substr(creationDate,12)
   # cDepoch=lt(cDdate,cDtime,"MST") ;# you sorry people in DST figure it out yourself
   last_cDdate=cDdate
   startDate=$(NF-6) " " $(NF-5)
   sub("startDate=\"","",startDate)
   sub("\"","",startDate)
   endDate=$(NF-3) " " $(NF-2)
   sub("endDate=\"","",endDate)
   sub("\"","",endDate)
   value=$NF
   sub("value=\"","",value)
   sub("\"/>","",value)
   sub("\">","",value)
   value=value+0   ; # make a number (This will make null values zero)
   # stats for each date
   t_d=type "_" cDdate
   N[t_d]++
   Min[t_d]=MIN( Min[t_d], value)
   Max[t_d]=MAX( Max[t_d], value)
   sumX[t_d]=sumX[t_d]+value
   sumX2[t_d]=sumX2[t_d]+(value*value)
#  if (last_cDdate != cDdate ) {
#     cnt_cD_file++
#     if (cnt_file != 1 ) { close(ocDfile) }
#     ofile=DIR "/" type ".csv"
#     NcD[type]++
#     }
   if(DEBUG) {
      print ""
      print "NR = " NR " ; NF = " NF
      print "type '" type "'"
      print "creationDate '" creationDate "'"
      print "startDate '" startDate "'"
      print "endDate '" endDate "'"
      print "value '" value "' unit '" unit "'"
      }
   # print cDepoch ", " creationDate ", " value >> ofile
   print  creationDate ", " value >> ofile
   }
END {
   close(ofile) 
   close(iofile) 
   print "End: 'InstantaneousBeatsPerMinute' From " istart " to " istop " with " icnt " bpm values."
   for (t in Types) {
      ocDfile=DIR "/" t "_tg.csv"
      if (t == "IrregularHeartRhythmEvent" ) {
         # print "@ \"Cummulative_" t "\"" > ocDfile
         print " " > ocDfile
         }
      else {
         print "@ Mean " t ", Max " t ", Sigma " t > ocDfile
         }
      print "" >> ocDfile
      for (t_d in N) {
         lcDd=length(t_d)
         date = substr(t_d, lcDd-9) 
         # print date
         # if (index(t_d, t"_2") > 0 ) {
         if (t_d == t "_" date)   {
            sigma=STDV( N[t_d], sumX[t_d], sumX2[t_d] )
            mean=mu
            # N and Min(always 0) donot provide information, so remove
            #     N[t_d] ", " \
            #     Min[t_d] ", " \
            #
            if (t == "IrregularHeartRhythmEvent" ) {
               print date ", " \
                     sumX[t_d] >> ocDfile 
               }
            else {
               print date ", " \
                     mean ", " \
                     Max[t_d] ", " \
                     sigma >> ocDfile 
               }
            } ; # end if
         } ; # end for t_d
      print "   ... Finished writing  termgraph file '" ocDfile "'"
      close(ocDfile)
      } ; # end for t
   }
