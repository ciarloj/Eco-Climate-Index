load "/home/netapp-clima/users/jciarlo/records-tool/tools/trimPNG.ncl"

begin

  spc = getenv("spc") ;"apis-mellifera-ligustica"
  dbs = getenv("obs") ;"iNaturalist"
  nam = getenv("nam") ; "MOHC-HadGEM2-ES_r1i1p1_ICTP-RegCM4-6"
  idir = getenv("idir") ; "/home/netapp-clima-scratch/jciarlo/paleosim/images/"
  tdir = getenv("tdir")
  stnf = getenv("flog")  
  gridf = getenv("fgrd") 
  idx = getenv("mg")
  ilat = getenv("lat")
  ilon = getenv("lon")

  formo = "png"
  outim = idir+"heatmap_"+spc+"_"+dbs
  wks   = gsn_open_wks(formo,outim)           ; send graphics to PNG file

;; get grid
  gf = addfile(gridf,"r")
  v = gf->$idx$(0,:,:)
  lat = gf->$ilat$
  lon = gf->$ilon$
  dims = dimsizes(lat)
  ndims = dimsizes(dims)
  if ( ndims.gt.1 ) then
    nlat = dims(1)
    nlon = dims(0)
  else
    nlat = dims
    nlon = dimsizes(lon)
  end if

 ;print(lon(0,0))
 ;print(lon(0,nlat-1))
 ;print(lon(nlon-1,0))
 ;print(lon(nlon-1,nlat-1))

  g = v-v

;; extract data from log file
  nrows = numAsciiRow(stnf)
  lines := asciiread(stnf,(/nrows/),"string")
  lines := lines(1:nrows-1)

  lats = new((/nrows-1/),"float")
  lons = new((/nrows-1/),"float")
  do n=0 , nrows-2
    print((n+1)+"/"+(nrows-1)+" ...")
    lsplt = tofloat(str_split(lines(n)," "))
    lats(n) = lsplt(1)
    lons(n) = lsplt(2)

    y = 1  
    do while(y.le.nlat-2)
      x = 1
      do while(x.le.nlon-2)
        if ( ndims.gt.1 ) then
          ln0 = lon(y,x)
          ln1 = lon(y,x+1)
          lt0 = lat(y,x)
          lt1 = lat(y+1,x)
        else
          ln0 = lon(x)
          ln1 = lon(x+1)
          lt0 = lat(y)
          lt1 = lat(y+1)
        end if
        ln  = lons(n)
        lt  = lats(n)
        if ( ln.ge.ln0 .and. ln.lt.ln1 .and. lt.ge.lt0 .and. lt.lt.lt1 ) then 
         ;print("added")
          g(y,x) = g(y,x)+1
          y = nlat
          x = nlon
        end if
        x = x+1
      end do
      y = y+1
    end do
  end do

  g = where(g.le.0,g@_FillValue,g)

  print("saving to nc..")
  newf = tdir+spc+"_"+dbs+"_"+nam+".nc"
  system("cp "+gridf+" "+newf)
  nf = addfile(newf,"w")
  nf->nobs = nf->$idx$
  nf->nobs = (/g/)

  if ( ndims.gt.1 ) then
    g@lat2d = lat
    g@lon2d = lon
  else
    g@lat = lat
    g@lon = lon
  end if

  cmap = read_colormap_file("cmocean_phase")  ; read color map
  cmap = cmap(::-1,:)                         ; reverse the color map

  res                             = True
  res@gsnMaximize                 = True
  res@gsnFrame                    = True                                 
  res@gsnDraw                     = True 

  mx = max(g)
  res@cnLevelSelectionMode        = "ManualLevels"
  res@cnMinLevelValF              = 1          	; 15.25
  res@cnMaxLevelValF              = mx		; 49.75
  res@cnLevelSpacingF             = tointeger(mx/6)

  res@cnFillOn                    = True
  res@cnFillPalette               = cmap ;(5:12,:)
  res@cnFillMode                  = "RasterFill"

  res@lbOrientation               = "vertical"
  res@lbBoxLinesOn                = False

;---Zoom in on map area of interest
  res@mpLimitMode       = "Corners"            ; choose range of map
  res@mpLeftCornerLatF  = min(lats)-1 ;lat(0,0)
  res@mpLeftCornerLonF  = min(lons)-1 ;lon(0,0)
  res@mpRightCornerLatF = max(lats)+1 ;lat(nlon-1,nlat-1)
  res@mpRightCornerLonF = max(lons)+1 ;lon(nlon-1,nlat-1)

; prj = gf@projection
; clon = gf@longitude_of_projection_origin
; if (prj .eq. "LAMCON") then
;   trlats = gf@standard_parallel
;   res@mpProjection        = "LambertConformal"
;   res@mpLambertParallel1F = trlats(0)
;   res@mpLambertParallel2F = trlats(1)
;   res@mpLambertMeridianF  = clon
; end if

  res@mpDataBaseVersion = "HighRes"           ; choose higher resolution

  res@tfDoNDCOverlay         = False     ; do not transform
  res@cnFillOn               = True      ; color plot desired
  res@cnLinesOn              = False       ; no contour lines
  res@cnLineLabelsOn         = False

  res@mpGeophysicalLineColor = "black"     ; color of continental outlines
  res@mpPerimOn              = True      ; draw box around map
  res@mpGridLineDashPattern  = 5         ; lat/lon lines as dashed

  res@gsnAddCyclic           = False     ; regional data don't add
  res@pmTickMarkDisplayMode  = "Always"  ;
  res@mpGridAndLimbOn        = True                ; turn on grid lines

; res@tmYROn = False            ; Turn off right tickmarks.
; res@tmXTOn = False            ; Turn off top tickmarks.
; res@tmYLOn = False
; res@tmXBOn = False
; res@mpFillOn                    = True

  mx=max(g)
  print("max="+mx)
  spcspc = str_sub_str(spc,"-"," ")
  res@tiMainString = spcspc

  plot = gsn_csm_contour_map(wks,g,res)
  trimPNG(outim+"."+formo)

end 
