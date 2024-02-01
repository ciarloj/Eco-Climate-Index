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
  onam = getenv("onam") ;"iNaturalist"
  yrs   = getenv("yrs")   ;"1995-1999"
  tdim  = getenv("tdim")  ;"1d"

  nboot = getenv("nboot")
  spc   = getenv("spc")

  slog  = getenv("slog")
  edir  = getenv("edir")
  bnam  = getenv("bnam") 

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
    dshort = gmod+"-"+rmod
  end if
  if ( dtyp .eq. "OBS" ) then
    dshort = dnam
    if ( dnam.eq."EOBS-010-c25e" ) then
      dshort = "EOBS"
    end if
  end if

  idir  = hdir+"/images/"
  outim = idir+"components_"+dnam+"_"+onam+"_"+spc+"_"+yrs+"_panel"
  formo = "png"
  wks   = gsn_open_wks (formo,outim)             ; send graphics to PNG file

  spcc  = str_split(spc,"-")
  spc_t = str_capital(spcc(0))+" "+spcc(1)
  print("preparing "+spc_t+" (nboot="+nboot+")")

  varlist = asciiread(slog,1,"string")
  vars  = str_split(varlist," ")
  nvar  = dimsizes(vars)
  vars := vars(3:nvar-1)
  nvar := dimsizes(vars)

  plot = new(nvar,graphic)

  do n=0 , nvar-1
    var = vars(n)
    print("..."+var+"...")

    ddir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/boot_"+nboot+"/ndis/"
    dfil = ddir+var+"_"+dnam+"_"+onam+"_"+spc+"_"+yrs+".nc" 
    f = addfile(dfil, "r")
    if ( var.eq."orog" ) then
      vi = f->comp(:,:)
    else
      vi = f->comp(0,:,:)
    end if

    if ( tdim.eq."2d" ) then
      xlat = f->lat
      xlon = f->lon
;     rpol = f->rotated_latitude_longitude
;     plat = rpol@grid_north_pole_latitude
;     plon = rpol@grid_north_pole_longitude
      vi@lat2d = xlat
      vi@lon2d = xlon
      dims = dimsizes(xlat)
      nlat = dims(0)
      nlon = dims(1)
    end if
    if ( tdim.eq."1d" ) then
      xlat = f->latitude
      xlon = f->longitude
;     xlon = where(xlon.lt.0,xlon+360,xlon)
      nlat = dimsizes(xlat)
      nlon = dimsizes(xlon)
      vi@lat = xlat
      vi@lon = xlon
    end if

   ;***********************
   ; plot
   ;***********************

    res  = True
    res@gsnDraw             = False
    res@gsnFrame            = False            

    res@mpLimitMode       = "Corners"            ; choose range of map
    res@tfDoNDCOverlay         = True      ; do not transform
    region = "Domain"
    if ( tdim.eq."2d" ) then
      res@tfDoNDCOverlay        = False      ; do not transform
     ;res@mpProjection        = "CylindricalEquidistant"
      dllon = 0
      dllat = 0
      drlon = 0
      drlat = 0
      if ( region.eq."Domain" ) then
        res@mpLeftCornerLatF  = xlat(0,0) + dllat
        res@mpLeftCornerLonF  = xlon(0,0) + dllon
        res@mpRightCornerLatF = xlat(nlat-1,nlon-1) + drlat
        res@mpRightCornerLonF = xlon(nlat-1,nlon-1) + drlon
      end if
      if ( region.eq."Mediterranean" ) then
        res@mpLeftCornerLatF  =  31.878244
        res@mpLeftCornerLonF  = -11.569858
        res@mpRightCornerLatF = xlat(nlat-1,nlon-1) + drlat
        res@mpRightCornerLonF = xlon(nlat-1,nlon-1) + drlon
      end if
      res@mpCenterLonF = xlon(nlat/2,nlon/2) 
      res@mpCenterLatF = xlat(nlat/2,nlon/2)
;     if (prj .eq. "LAMCON") then
;       trlats = f@standard_parallel
;       res@mpProjection        = "LambertConformal"
;       res@mpLambertParallel1F = trlats(0)
;       res@mpLambertParallel2F = trlats(1)
;       res@mpLambertMeridianF  = clon
;     end if
;     if (prj .eq. "NORMER") then
;       res@mpProjection        = "Mercator"
;     end if
;     if (prj .eq. "ROTMER") then
;       clat = ff@latitude_of_projection_origin
;       res@mpProjection        = "Mercator"
;       res@mpCenterLonF = clon
;       res@mpCenterLatF = clat
;     end if
    end if
    if ( tdim.eq."1d" ) then
      if ( region.eq."Domain" ) then
        res@mpLeftCornerLatF  = min(xlat)
        res@mpLeftCornerLonF  = min(xlon)
        res@mpRightCornerLatF = max(xlat)
        res@mpRightCornerLonF = max(xlon)
      end if
      if ( region.eq."Mediterranean" ) then
        res@tfDoNDCOverlay    = False      ; do not transform
        res@mpLeftCornerLatF  =  31.878244
        res@mpLeftCornerLonF  =  11.569858
        res@mpRightCornerLatF =  57.683023
        res@mpRightCornerLonF =  42.361506
      end if
    end if

  ; usually, when data is placed onto a map, it is TRANSFORMED to the specified
  ; projection. Since this model is already on a native lambert conformal grid,
  ; we want to turn OFF the tranformation.

    res@cnFillOn               = True      ; color plot desired
    res@cnFillMode             = "RasterFill"
    res@cnLinesOn              = False       ; no contour lines
    res@mpFillOn               = False

    res@mpGeophysicalLineColor = "black"     ; color of continental outlines
    res@mpPerimOn              = True      ; draw box around map
    res@mpGridLineDashPattern  = 5         ; lat/lon lines as dashed

;   res@gsnAddCyclic           = False     ; regional data don't add
;   res@pmTickMarkDisplayMode  = "Always"  ;
    res@mpGridAndLimbOn        = False               ; turn on grid lines
    res@lbLabelBarOn           = False
;   res@lbOrientation          =   "vertical"
;  ;res@lbLabelFontHeightF   = 0.02
;   res@lbTitleFontHeightF   = 0.018                ; make title smaller
;  ;res@lbTitlePosition      = "Top"
    res@tmYROn = False            ; Turn off right tickmarks.
    res@tmXTOn = False            ; Turn off top tickmarks.
    res@tmYLOn = False
    res@tmXBOn = False
    res@gsnLeftString          = "" 
    res@gsnRightString         = ""
;   res@gsnLeftStringFontHeightF  = 0.01
    res@gsnRightStringFontHeightF = 0.013
    res@gsnCenterString        = var
    res@mpDataBaseVersion    = "HighRes"

    res@cnLevelSelectionMode   = "ExplicitLevels"
;   res@cnConstFLabelFormat    = "0f1"
    res@cnLevels = (/.1,.2,.3,.4,.5,.6,.7,.8,.9,1/) 
    cmap = read_colormap_file("WhiteBlueGreenYellowRed")
;   cmap = cmap(::-1,:) ; reverse the color map
    res@cnFillPalette = cmap

    plot(n) = gsn_csm_contour_map(wks,vi,res)

  end do

  ;---------------------------------------------
  ; create panel
  ;---------------------------------------------
  pres                  = True
  pres@gsnPanelLabelBar = True
  pres@lbOrientation =   "vertical"
  pres@lbLabelFontHeightF   = 0.01
  pres@lbTitleFontHeightF   = 0.01             ; make title smaller
  pres@lbTitleString    = "(#)"
  pres@lbTitlePosition      = "Top"
  pres@gsnMaximize = True
  pres@gsnPanelRight  = 0.97
  pres@gsnScale = True
  pres@gsnPanelMainString = spc_t

  gsn_panel(wks,plot,(/3,3/),pres)
  trimPNG(outim+"."+formo)

end
