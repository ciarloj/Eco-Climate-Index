;***********************************************************
; pdf_1.ncl
;
; Concepts illustrated:
;   - Generating univariate probability distributions
;   - Generating PDFs of each sample distribution
;   - Paneling two plots horizontally on a page
;***********************************************************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"   
load "tools/trimPNG.ncl"

begin

  hdir = getenv("hdir") ;"/home/netapp-clima-scratch/jciarlo/paleosim"
  dtyp = getenv("dtyp") ;"CPMs"
  dnam = getenv("dnam") ;"ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0_CP"
  yrs   = getenv("yrs")   ;"1995-1999"
  ivars = getenv("indices") 
  varlist = getenv("varlist")

  if ( dtyp .eq. "CPMs" ) then
    dnam_splt = str_split(dnam,"_")
    glob = dnam_splt(0)
    if ( glob.eq."ECMWF-ERA5" ) then
      gmod = "ERA5"
    end if
    regi = dnam_splt(2)
    if ( regi.eq."ICTP-RegCM5-0" ) then
      rmod = "RegCM5"
    end if
    if ( regi.eq."ICTP-RegCM5-0-BATS" ) then
      rmod = "RegCM5-BATS"
    end if
    dshort = gmod+"-"+rmod
  end if
  if ( dtyp .eq. "OBS" ) then
    dshort = dnam
    if ( dnam.eq."EOBS-010-c25e" ) then
      dshort = "EOBS"
    end if
  end if

  idir  = hdir+"/images/"
  outim = idir+"bias_"+dnam+"_"+yrs
  formo = "png"
  imgres = 1500
  formo@wkWidth = imgres
  formo@wkHeight = imgres
  wks   = gsn_open_wks (formo,outim)             ; send graphics to PNG file

  indices = str_split(ivars," ")
  varsrcs = str_split(varlist," ")
  nidx = dimsizes(indices)

  plot = new(nidx,graphic)
  dumP = new(nidx,graphic)

  do n=0 , nidx-1
    idx = indices(n)
    var = varsrcs(n)
    print("preparing "+idx+" ...")

    ddir = hdir+"/data/"+dtyp+"/"+dnam+"/index/bias/"
    dfil = ddir+var+"_"+idx+"_"+dnam+"_"+yrs+".nc" 
    if ( idx.eq."orog" ) then
      dfil = ddir+var+"_"+idx+"_"+dnam+".nc"
    end if
    f = addfile(dfil, "r")
    cdimz = dimsizes(dimsizes(f->$idx$))
    if ( cdimz.eq.2 ) then
      bi := f->$idx$(:,:)
    else if ( cdimz.eq.3 ) then
      bi := f->$idx$(0,:,:)
    else if ( cdimz.eq.4 ) then
      bi := f->$idx$(0,0,:,:)
    end if
    end if
    end if

;   if ( tdim.eq."2d" ) then
;     if ( dtyp .eq. "CPMs" ) then
;       xlat = f->xlat
;       xlon = f->xlon
;     else 
;       xlat = f->lat
;       xlon = f->lon
;     end if 
;;    rpol = f->rotated_latitude_longitude
;;    plat = rpol@grid_north_pole_latitude
;;    plon = rpol@grid_north_pole_longitude
;     bi@lat2d = xlat
;     bi@lon2d = xlon
;     dims = dimsizes(xlat)
;     nlat = dims(0)
;     nlon = dims(1)
;   end if
      xlat := f->latitude
      xlon := f->longitude
;     xlon = where(xlon.lt.0,xlon+360,xlon)
      nlat = dimsizes(xlat)
      nlon = dimsizes(xlon)
      bi@lat := xlat
      bi@lon := xlon

   ;***********************
   ; plot
   ;***********************

    res  = True
    res@gsnDraw             = False
    res@gsnFrame            = False            

    res@mpLimitMode       = "Corners"            ; choose range of map
    res@tfDoNDCOverlay         = True      ; do not transform
    region = "Domain"
    if ( dtyp.eq."CPMs" ) then
      region = "Mediterranean"
    end if
;   if ( tdim.eq."2d" ) then
;     res@tfDoNDCOverlay        = False      ; do not transform
;     dlon = 0.
;     dlat = 0.
;     if ( dtyp .eq. "RCMs" ) then
;       dlon = 8.25
;       dlat = 1.5
;     end if
;
;     dllon = 0
;     dllat = 0
;     drlon = 0
;     drlat = 0
;     if ( region.eq."Domain" ) then
;       res@mpLeftCornerLatF  = xlat(0,0) + dllat
;       res@mpLeftCornerLonF  = xlon(0,0) + dllon
;       res@mpRightCornerLatF = xlat(nlat-1,nlon-1) + drlat
;       res@mpRightCornerLonF = xlon(nlat-1,nlon-1) + drlon
;     end if
;     res@mpCenterLonF = xlon(nlat/2,nlon/2) + dlon 
;     res@mpCenterLatF = xlat(nlat/2,nlon/2) + dlat
;   end if
    if ( region.eq."Domain" ) then
      res@mpLeftCornerLatF  = min(xlat)
      res@mpLeftCornerLonF  = min(xlon)
      res@mpRightCornerLatF = max(xlat)
      res@mpRightCornerLonF = max(xlon)
    end if
    if ( region.eq."Europe" ) then
      res@gsnAddCyclic      = False
      res@tfDoNDCOverlay    = False      ; do not transform
      res@mpLeftCornerLatF  = 29.
      res@mpLeftCornerLonF  = -9.
      res@mpRightCornerLatF = 47.
      res@mpRightCornerLonF = 34.5
    end if
    if ( region.eq."Mediterranean" ) then
      res@gsnAddCyclic      = False
      res@tfDoNDCOverlay    = False      ; do not transform
      res@mpLeftCornerLatF  = 29.
      res@mpLeftCornerLonF  = -9.5
      res@mpRightCornerLatF = 47.
      res@mpRightCornerLonF = 34.5
    end if

  ; usually, when data is placed onto a map, it is TRANSFORMED to the specified
  ; projection. Since this model is already on a native lambert conformal grid,
  ; we want to turn OFF the tranformation.

    res@cnFillOn               = True      ; color plot desired
    res@cnFillMode             = "RasterFill"
    res@cnLinesOn              = False       ; no contour lines
    res@cnLineLabelsOn         = False       ; no contour line labels
    res@cnMissingValFillPattern = "SolidFill"
    res@cnMissingValFillColor = "grey75"
    res@mpFillOn               = False

    res@mpGeophysicalLineColor = "black"     ; color of continental outlines
    res@mpPerimOn              = True      ; draw box around map
    res@mpGridLineDashPattern  = 5         ; lat/lon lines as dashed

    res@mpGridAndLimbOn        = False               ; turn on grid lines
    res@lbLabelBarOn           = False
    res@tmYROn = False            ; Turn off right tickmarks.
    res@tmXTOn = False            ; Turn off top tickmarks.
    res@tmYLOn = False
    res@tmXBOn = False
    res@gsnLeftString          = "" 
    res@gsnRightString         = ""
    res@gsnCenterString        = idx
    res@mpDataBaseVersion    = "HighRes"

    res@cnLevelSelectionMode   = "ExplicitLevels"
    res@cnLevels = (/-5,-4,-3,-2,-1,-.5,.5,1,2,3,4,5/)
    cmap = read_colormap_file("BlueWhiteOrangeRed")
    res@cnFillPalette = cmap

    plot(n) = gsn_csm_contour_map(wks,bi,res)

  end do

  ;---------------------------------------------
  ; create panel
  ;---------------------------------------------
  pres                  = True
  pres@gsnPanelLabelBar = True
  pres@lbOrientation =   "vertical"
  pres@lbLabelFontHeightF   = 0.01
  pres@lbTitleFontHeightF   = 0.01             ; make title smaller
  pres@lbTitleString        = "(%)"
  pres@lbTitlePosition      = "Top"
  pres@gsnMaximize = True
  pres@gsnPanelRight  = 0.97
  pres@gsnScale = True

  gsn_panel(wks,plot,(/3,3/),pres)
  trimPNG(outim+"."+formo)

end
