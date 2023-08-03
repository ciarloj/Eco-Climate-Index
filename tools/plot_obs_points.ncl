load "/home/netapp-clima/users/jciarlo/records-tool/tools/trimPNG.ncl"

begin

  spc = getenv("spc") ;"apis-mellifera-ligustica"
  dbs = getenv("dbs") ;"iNaturalist"
  dom = getenv("dom") ;"italy"
  obs = spc+"_"+dbs+"_"+dom
  rcm = "MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6"

  idir = "/home/netapp-clima-scratch/jciarlo/paleosim/images/"
  system("mkdir -p "+idir)
  formo = "png"
  outim = idir+"obsmap_"+obs
  wks   = gsn_open_wks(formo,outim)           ; send graphics to PNG file

;; extract data from log file
  ddir = "data/RCMs/"+rcm+"/index/"
  stnf = ddir+obs+"_"+rcm+".log"
  nrows = numAsciiRow(stnf)
  lines := asciiread(stnf,(/nrows/),"string")
  lines := lines(1:nrows-1)

  lats = new((/nrows-1/),"float")
  lons = new((/nrows-1/),"float")
  do n=0 , nrows-2
print(""+(n+1))
    lsplt = tofloat(str_split(lines(n)," "))
    lats(n) = lsplt(1)
    lons(n) = lsplt(2)
  end do

  res                             = True
  res@gsnMaximize = True
  res@gsnDraw     = False
  res@gsnFrame    = False
; res@mpFillOn                    = False        ; turn off gray fill
; res@mpOutlineBoundarySets       = "National"   ; turn on country boundaries
; res@mpGeophysicalLineColor      = "Navy"       ; color of cont. outlines
; res@mpGeophysicalLineThicknessF = 1.5          ; thickness of outlines
  res@mpGridLineDashPattern  = 5         ; lat/lon lines as dashed
  res@mpGridAndLimbOn        = True                ; turn on grid lines

  spcspc = str_sub_str(spc,"-"," ")
  res@tiMainString = spcspc

  res@mpMaxLatF              = max(lats)+1 ;75           ; choose a different subregion
  res@mpMinLatF              = min(lats)-1 ;30
  res@mpMaxLonF              = max(lons)+1 ;50
  res@mpMinLonF              = min(lons)-1 ;-12
  res@mpDataBaseVersion = "HighRes"           ; choose higher resolution

  plot = gsn_csm_map(wks,res)                   ; draw map

  mkres = True
  mkres@gsMarkerIndex = 16 ; filled circle
  mkres@gsMarkerSizeF = 3.0
  mkres@gsMarkerColor = "black"

  marks  = gsn_add_polymarker(wks,plot,lons,lats,mkres)
  delete(lats)
  delete(lons)

  resP = True
  maximize_output(wks,resP)
 
  print("saved")
  trimPNG(outim+"."+formo)


  end
