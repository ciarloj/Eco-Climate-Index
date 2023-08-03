load "/home/netapp-clima/users/jciarlo/records-tool/tools/trimPNG.ncl"

begin

  ;; input parameters
  indx = getenv("indx")
  flog = getenv("flog")
  odir = getenv("odir")
  spc  = getenv("spc")
  obs  = getenv("obs")
  print("## Calculating statistics for "+indx+" ##")

  ;; prepare output
  outn  = "/"+spc+"_"+obs+"_bootPDF_"+indx
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
    bf = 5  ;; set bin-factor to set the number of bins relative to values
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

  ;***************************************************************
  ; https://www.ncl.ucar.edu/Document/Functions/Contributed/generate_sample_indices.shtml
  ;***************************************************************
  nBoot = 1000                          ; bootstrap replications
  NN    = ndim                          ; number of samples in dataset
 
  vBoot = new((/ndim*nBoot/),typeof(vals))
  do n=0 , nBoot-1
if (indx.eq."r99") then
print (""+(n+1))
end if
    iw = generate_sample_indices( NN, 1 )  ; with replacement
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

  imin = tointeger(minb-1)
  imax = tointeger(maxb+1)
  nbins = tointeger(tofloat((imax-imin))/bf)

  opt          = True
; opt@bin_nice = True
  opt@bin_min  = imin
  opt@bin_max  = imax
  ipdf = pdfx(vBoot,nbins,opt)

  plot = gsn_csm_xy(wks,ipdf@bin_center,ipdf,True)

; use of mode would be better than average
; stdev could be better in two values for each side
; similaryl might need to change N

; updated standard system
  nx = abs((p90b-avgb)/stdb)
  nn = abs((p10b-avgb)/stdb)
  N  = max((/nx,nn/))

  print(stdb+","+avgb+","+N+","+odir+outn+".png")

exit 

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
  res@gsnCenterString               = str_sub_str(spc,"-"," ") 

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

  ;; draw mean line
  res_line                   = True
  res_line@gsLineColor       = "black"
  res_line@gsLineThicknessF  = 4
  res_line@gsLineDashPattern = 0
  xN = avgb
  y0 = miny
  yN = maxy
  dum1 = gsn_add_polyline(wks,plot,(/xN,xN/),(/y0,yN/),res_line)

  ;; draw stdev lines
  res_line@gsLineDashPattern = 1
  x1 = avgb+stdb
  x2 = avgb-stdb
  dum2 = gsn_add_polyline(wks,plot,(/x1,x1/),(/y0,yN/),res_line)
  dum3 = gsn_add_polyline(wks,plot,(/x2,x2/),(/y0,yN/),res_line)

  ;; draw max limit
  res_line@gsLineColor       = "red"
  x3 = avgb+(N*stdb)
  x4 = avgb-(N*stdb)
  dum4 = gsn_add_polyline(wks,plot,(/x3,x3/),(/y0,yN/),res_line)
  dum5 = gsn_add_polyline(wks,plot,(/x4,x4/),(/y0,yN/),res_line)

  resP             = True
  maximize_output(wks,resP)
; trimPNG(odir+outn+".png")

end
