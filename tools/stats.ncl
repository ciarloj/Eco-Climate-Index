load "/home/netapp-clima/users/jciarlo/records-tool/tools/trimPNG.ncl"

begin

  ;; input parameters
  ncomp = stringtointeger(getenv("ncomp"))
  cn    = stringtointeger(getenv("cn"))
  scrf  = getenv("scrf")
; print("## Calculating statistics for "+cn+"/"+ncomp+" ##")

  ;; extract data from log file
  nrows = numAsciiRow(scrf)
  lines := asciiread(scrf,(/nrows/),"string")
  heads := lines(0)
  lines := lines(1:nrows-1)

  hchar := stringtochar(heads)
  if ( hchar(2).eq."," ) then
    fdel = ","
  else
    fdel = " "
  end if

  compt = new((/nrows/),"string")
  do l=0 , nrows-2
    lsplt = str_split(lines(l),fdel)
    compt(l) = lsplt(cn)
  end do
  compx = stringtofloat(compt)

  mean = avg(compx)
  stdv = stddev(compx)
  maxc = max(compx)
  minc = min(compx)

  ; using Carling's modification to identify limits of outliers instead of max/min
  n = nrows-1 ; sample size
  k = ((17.62*n)-23.64)/((7.74*n)-3.71)
  medc = dim_median(compx) ; median
  statc = stat_dispersion(compx,False)
  p25c = statc(6)  ; q1
  p75c = statc(10) ; q2
  btlim = medc - (k*(p75c-p25c)) 
  tplim = medc + (k*(p75c-p25c))
  
  maxc = tplim
  ; some variables have a lower value of 0 (like pr) which may get negative btlim
  ; in these cases we take the minimum as the limit
  if ( minc .lt. btlim ) then
    minc = btlim
  end if

; initial simplified standard system
  nx = abs((maxc-mean)/stdv)
  nn = abs((minc-mean)/stdv)
  N  = max((/nx,nn/))

  print(stdv+","+mean+","+N)

end
