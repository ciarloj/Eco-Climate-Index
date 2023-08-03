load "/home/netapp-clima/users/jciarlo/records-tool/tools/trimPNG.ncl"

begin

  ;; input parameters
  indx = getenv("indx")
  flog = getenv("flog")
  odir = getenv("odir")
  spc  = getenv("spc")
  obs  = getenv("obs")
; print("## Calculating statistics for "+indx+" ##")

  ;; prepare output
  outn  = "/"+spc+"_"+obs+"_PDF_"+indx
  wks   = gsn_open_wks("png",odir+outn)

  ;; extract data from log file
  nrows = numAsciiRow(flog)
  lines := asciiread(flog,(/nrows/),"string")
  heads := lines(0)
  lines := lines(1:nrows-1)

  styl = "line"
  if ( indx.eq."cdd" ) then 
    nm = "Consecutive Dry Days (days/year)"
    nv = 3  ;; 4th with starting value as 0
    bf = 10 ;; set bin-factor to set the number of bins relative to values
  end if
  if ( indx.eq."r99" ) then
    nm = "Total Rainfall above P99 (mm/year)" 
    nv = 4  
    bf = 0.25
  end if
  if ( indx.eq."hwfi" ) then
    nm = "Heat Wave Frequency Index (days/year)"
    nv = 5
    bf = 2
  end if
  if ( indx.eq."cwfi" ) then
    nm = "Cold Wave Frequency Index (days/year)"
    nv = 6
    bf = 3
  end if
  if ( indx.eq."mrsomean" ) then
    nm = "Mean Soil Moisture Content (kg/m2/year)" 
    nv = 7
    bf = 0.025
  end if
  if ( indx.eq."fg6bft" ) then
    nm = "Days with wind speed above BFT6 (days/year)" 
    nv = 8
    bf = 1
    styl = "mark"
  end if
  if ( indx.eq."windmean" ) then
    nm = "Average wind speed (m/s)"
    nv = 8
    bf = 1
    styl = "mark"
  end if
  if ( indx.eq."orog" ) then
    nm = "Elevation (m)"
    nv = 9
    bf = 0.025
    styl = "mark"
  end if
  
  heads := str_split(heads," ")
  ncols = dimsizes(heads)
  do h=0 , ncols-1
    if ( heads(h).eq.indx ) then
      nv = h
      break
    end if
  end do
 
  vals = new((/nrows-1/),"float")
  do n=0 , nrows-2
    lsplt = tofloat(str_split(lines(n)," "))
    vals(n) = lsplt(nv)
  end do
  ndim = dimsizes(vals)

  stat = stat_dispersion(vals, False)
  p10v = stat(3) ; lower dectile
  p90v = stat(13) ; upper dectile

  stdv = stddev(vals)
  avgv = avg(vals)
  maxv = max(vals)
  minv = min(vals)   
  print("DATA: min,p10,mean,stdv,p90,max = "+minv+","+p10v+","+avgv+","+stdv+","+p90v+","+maxv)

  lboot = True
  if ( lboot.eq.True ) then
    ;***************************************************************
    ; https://www.ncl.ucar.edu/Document/Functions/Contributed/generate_sample_indices.shtml
    ;***************************************************************
    nBoot = 1000                          ; bootstrap replications
    N  = ndim                             ; number of samples in dataset
 
    vBoot = new((/ndim*nBoot/),typeof(vals))
    do n=0 , nBoot-1
      iw = generate_sample_indices( N, 1 )  ; with replacement
      nA = 0+(n*ndim)
      nB = (ndim-1)+(n*ndim)
      iwvals = vals(iw)
      vBoot(nA:nB) = iwvals(:)
    end do

    stat = stat_dispersion(vBoot, False)
    p10b = stat(3) ; lower dectile
    p90b = stat(13) ; upper dectile
    stdb = stddev(vBoot)
    avgb = avg(vBoot)
    maxb = max(vBoot)
    minb = min(vBoot)
    print("After "+nBoot+" BootStraps")
    print("Boot: min,p10,mean,stdv,p90,max = "+minb+","+p10b+","+avgb+","+stdb+","+p90b+","+maxb)
;    print("Boot: min,mean,max = "+minb+","+avgb+","+maxb)

    imin = tointeger(minv-1)
    imax = tointeger(maxv+1)
    nbins = tointeger(tofloat((imax-imin))*bf)

  opt          = True
  opt@bin_nice = True
  opt@bin_min  = imin
  opt@bin_max  = imax
  ipdf = pdfx(vBoot,nbins,opt)

  plot = gsn_csm_xy(wks,ipdf@bin_center,ipdf,True)

print("look for "+odir+outn+".png")
exit

    ;***************************************************************
    ;--- bootstrap_stat: extract information from returned 'list' variable: Bootstrap
    ;***************************************************************
    ;; https://www.ncl.ucar.edu/Document/Functions/Bootstrap/bootstrap_stat.shtml
    ;; opt@sample_size=N is the default
    ;; opt@sample_method=1 specifies sampling-with-replacement. This is the default.

    BootStrap = bootstrap_stat(vals, bstat, nBoot, nDim, opt)
                                ; For 'clarity' extract from 'list' variable
    xBoot     = BootStrap[0]    ; Bootstrapped values in ascending order (use for histogram)
 
    avgb = avg(xBoot)
    maxb = max(xBoot)
    minb = min(xBoot)
    print("Boot: min,mean,max = "+minb+","+avgb+","+maxb)

    ;printVarSummary(BootStrap)
    ;printVarSummary(xBoot)

 

exit


  else
    stat = stat_dispersion(vals, False)
    nval = stat(19) ; Number of input values used for statistics ;; num(vals)
  ; mean = avg(vals)
    ;stdv = stat(1)  ; standard deviation                         ;; stddev(vals)
    minv = stat(2)  ; minimum                                    ;; max(vals)
    maxv = stat(14) ; maximum                                    ;; min(vals)
    ;p10v = stat(3) ; lower dectile
    ;p90v = stat(13) ; upper dectile
    ;; need more than 1000 values
    ;p01v = stat(23) ;  1th percentile
    ;p99v = stat(26) ; 99th percentile

    imin = tointeger(minv-1)
    imax = tointeger(maxv+1)
    nbins = tointeger(tofloat((imax-imin))*bf)
  end if


  opt          = True
; opt@bin_nice = True
  opt@bin_min  = imin
  opt@bin_max  = imax
  ipdf = pdfx(vals,nbins,opt)
;print(ipdf)
;print(ipdf@bin_center)

  peakfq = max(ipdf)
  nb = 0
  do n=0 , nbins-1
    if ( ipdf(n).eq.peakfq ) then
      nb = n
      break
    end if
  end do
  mode = imin*(nb+1)

  ;; data above the mode
  upperv = where(vals.le.mode,vals@_FillValue,vals)
  upperd = new((/2*ndim/), "float")
  upperd(0:ndim-1) = tofloat(upperv(:))
  upperd(ndim:2*ndim-1) = tofloat(upperv(:))
  uppers = stat_dispersion(upperd, False)
  mean1 = uppers(0)  ; mean
  stdv1 = uppers(1)  ; standard deviation                         ;; stddev(vals)
  p90v  = uppers(13) ; upper dectile
  ;; need more than 1000 values
  ;p99v = upper(26) ; 99th percentile
print(mean1+" "+stdv1+" "+p90v)

  ;; data below the mode
  lowerv = where(vals.ge.mode,vals@_FillValue,vals)
  lowerd = new((/2*ndim/), "float")
  lowerd(0:ndim-1) = tofloat(lowerv(:))
  lowerd(ndim:2*ndim-1) = tofloat(lowerv(:))
  lowers = stat_dispersion(lowerd, False)
  mean2 = lowers(0) ; mean
  stdv2 = lowers(1) ; standard deviation
  p10v  = lowers(3) ; lower dectile
  ;; need more than 1000 values
  ;p01v = lowers(23) ;  1th percentile

; initial simplified standard system
; nx = abs((maxv-mean)/stdv)
; nn = abs((minv-mean)/stdv)
; N  = max((/nx,nn/))

; updated standard system
  nx = abs((p90v-mode)/stdv1)
  nn = abs((p10v-mode)/stdv2)

  print(stdv+","+mean+","+N+","+odir+outn+".png")

  if ( styl.eq."mark" ) then
    ipdf = where(ipdf.eq.0,ipdf@_FillValue,ipdf)
  end if

  ;***********************
  ; plot
  ;***********************

  res             = True               ; plot mods desired
  res@gsnDraw     = True               
  res@gsnFrame    = False              ; don't advance frame yet
  res@gsnMaximize = True

  res@tmYROn      = False              ; Turn off right tickmarks.
  res@tmXTOn      = False              ; Turn off top tickmarks.

  maxy=max(ipdf)
  miny=min(ipdf)
  if ( styl.eq."line" ) then
    res@xyMarkLineMode    = "Lines"
    res@xyLineThicknessF  = (/3/)     ; Thicken the lines
    res@xyDashPatterns    = (/0/)
    res@xyLineColors      = (/"blue"/)
  end if
  if ( styl.eq."mark" ) then
    res@xyMarkLineMode    = "Markers"
    res@xyMarkers         = (/16/)
    res@xyMarkerColors    = (/"blue"/)
    res@xyMarkerSizeF     = 0.0050
    res@trYLog            = True
    res@xyComputeYMin     = True
  end if
  res@trXMinF           = 0.

  res@gsnCenterStringFontHeightF    = 0.02
  res@gsnCenterString               = "Apis mellifera"

  res@tmXBLabelFontHeightF = 0.018
  res@tmYLLabelFontHeightF = 0.018
  res@tiXAxisFontHeightF   = 0.02
  res@tiYAxisFontHeightF   = 0.02
  res@tiXAxisString        = nm
  res@tiYAxisString        = "frequency (%)"

  res@tiXAxisOn    = True
  res@tmXBLabelsOn = True

  plot = gsn_csm_xy(wks,ipdf@bin_center,ipdf,res)

  ;*****************************************************
  ; Attach markers 
  ;*****************************************************

  ;; draw mode line
  res_line                   = True
  res_line@gsLineColor       = "black"
  res_line@gsLineThicknessF  = 4
  res_line@gsLineDashPattern = 0
  xN = mode
  y0 = miny
  yN = maxy
  dum1 = gsn_add_polyline(wks,plot,(/xN,xN/),(/y0,yN/),res_line)

  ;; draw stdev lines
  res_line@gsLineDashPattern = 1
  x1 = mean1+stdv1
  x2 = mean2-stdv2
  dum2 = gsn_add_polyline(wks,plot,(/x1,x1/),(/y0,yN/),res_line)
  dum3 = gsn_add_polyline(wks,plot,(/x2,x2/),(/y0,yN/),res_line)

  ;; draw max limit
  res_line@gsLineColor       = "red"
  x3 = p90v
  x4 = p10v
  dum4 = gsn_add_polyline(wks,plot,(/x3,x3/),(/y0,yN/),res_line)
  dum5 = gsn_add_polyline(wks,plot,(/x4,x4/),(/y0,yN/),res_line)

  resP             = True
  maximize_output(wks,resP)
; trimPNG(odir+outn+".png")

end
