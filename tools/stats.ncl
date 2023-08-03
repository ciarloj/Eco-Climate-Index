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

  compt = new((/nrows/),"string")
  do l=0 , nrows-2
    lsplt = str_split(lines(l),",")
    compt(l) = lsplt(cn)
  end do
  compx = stringtofloat(compt)

  mean = avg(compx)
  stdv = stddev(compx)
  maxc = max(compx)
  minc = min(compx)

; initial simplified standard system
  nx = abs((maxc-mean)/stdv)
  nn = abs((minc-mean)/stdv)
  N  = max((/nx,nn/))

  print(stdv+","+mean+","+N)

end
