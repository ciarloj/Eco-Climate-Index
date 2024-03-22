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

  bootlist = str_split(getenv("bootlist")," ")  ;8
  spclist  = str_split(getenv("spclist")," ")   ;"polyommatus-celina"
  nspc = dimsizes(spclist)

  dp = getenv("dp")
; drawPoints = False
; if ( dp.eq."true" ) then
    drawPoints = True 
; end if
  drawSummary = False
  if ( dp.eq."summary" ) then
    drawSummary = True
  end if

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
  outim = idir+"EcoIndex_"+dnam+"_"+onam+"_"+yrs+"_panel"
  formo = "png"
  imgres = 2500
  formo@wkWidth = imgres
  formo@wkHeight = imgres
  wks   = gsn_open_wks (formo,outim)             ; send graphics to PNG file

  labs := (/"a","b","c","d","e","f","g","h","i","j","k"/)
  plot = new(nspc,graphic)
  dumP = new(nspc,graphic)

  do n=0 , nspc-1
    ilab  = "("+labs(n)+")"
    spc   = spclist(n)
    nboot = bootlist(n)
    spcc  = str_split(spc,"-")
;   spc_t = str_capital(spcc(0))+" "+spcc(1)
    spc_c := stringtochar(spcc(0))
    spc_t = str_capital(chartostring(spc_c(0)))+". "+spcc(1)
    print("preparing "+spc_t+" (nboot="+nboot+")")

    ddir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/boot_"+nboot+"/ndis/"
    dfil = ddir+"EcoIndex_"+dnam+"_"+onam+"_"+spc+"_"+yrs+".nc" 
    f = addfile(dfil, "r")
    ei = f->comp(0,:,:)

    if ( drawPoints.eq.True .or. drawSummary.eq.True ) then
      ;;; extract station data for plotting
      ldir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/"
      lfil = ldir+spc+"_"+onam+"_"+dnam+".log"

      ;; extract data from log file
      nrows = numAsciiRow(lfil)
      lines := asciiread(lfil,(/nrows/),"string")
      heads := lines(0)
      lines := lines(0:nrows-1)

      hchar := stringtochar(heads)
      fdel = " "
      ilon := new((/nrows-1/),"string")
      ilat := new((/nrows-1/),"string")
      do l=0 , nrows-2
        lsplt = str_split(lines(l),fdel)
        ilon(l) = lsplt(2)
        ilat(l) = lsplt(1)
      end do
      ilon := stringtofloat(ilon)
      ilat := stringtofloat(ilat)

      ;;; checking EI values at observation locations
      eldir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/boot_"+nboot+"/ndis/latlon/"
      elfil = eldir+"EcoIndex_"+dnam+"_"+onam+"_"+spc+"_"+yrs+".log"
      nlrows = numAsciiRow(elfil)
      elines := asciiread(elfil,(/nlrows/),"string")
      evals := elines(1:nlrows-1)
      evals := where(evals.eq."_",evals@_FillValue,evals)

      ilon = where(ismissing(evals),ilon@_FillValue,ilon)
      ilat = where(ismissing(evals),ilat@_FillValue,ilat)
      nval = int2flt(num(.not.ismissing(ilon)))
      th1 = 0.1
      ilon = where(evals.lt.th1,ilon,ilon@_FillValue)
      ilat = where(evals.lt.th1,ilat,ilat@_FillValue)
      nmis = int2flt(num(.not.ismissing(ilon)))
      if ( nval.eq.0 ) then
        npct = 0.0
        plab := "n/a"
      else
        npct = nmis*100/nval
        plab := npct
      end if

      if ( drawSummary ) then
        nvals = dimsizes(lines)
        nvald = num(.not.ismissing(evals)) ;number of valid points
 
        th1 = 0.1
        cl = num(evals.ge.th1)
        if ( nvald.eq.0 ) then
          pcl = 0.
        else
          pcl = cl*100./nvald
        end if
      end if

      ilon = where(ismissing(evals),ilon@_FillValue,ilon)
      ilat = where(ismissing(evals),ilat@_FillValue,ilat)
      ilon = where(evals.lt.th1,ilon,ilon@_FillValue)
      ilat = where(evals.lt.th1,ilat,ilat@_FillValue)

    ; print("Logging missed points...")
    ; print(">>> evals ilat ilon")
    ; print(">>> "+evals+" "+ilat+" "+ilon)

    end if

    if ( tdim.eq."2d" ) then
      if ( dtyp .eq. "CPMs" ) then
        xlat = f->xlat
        xlon = f->xlon
      else 
        xlat = f->lat
        xlon = f->lon
      end if 
;     rpol = f->rotated_latitude_longitude
;     plat = rpol@grid_north_pole_latitude
;     plon = rpol@grid_north_pole_longitude
      ei@lat2d = xlat
      ei@lon2d = xlon
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
      ei@lat = xlat
      ei@lon = xlon
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
      dlon = 0.
      dlat = 0.
      if ( dtyp .eq. "RCMs" ) then
        dlon = 8.25
        dlat = 1.5
      end if

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
      res@mpCenterLonF = xlon(nlat/2,nlon/2) + dlon 
      res@mpCenterLatF = xlat(nlat/2,nlon/2) + dlat
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
    end if

  ; usually, when data is placed onto a map, it is TRANSFORMED to the specified
  ; projection. Since this model is already on a native lambert conformal grid,
  ; we want to turn OFF the tranformation.

    res@cnFillOn               = True      ; color plot desired
    res@cnFillMode             = "RasterFill"
    res@cnLinesOn              = False       ; no contour lines
    res@cnLineLabelsOn         = False       ; no contour line labels
    res@mpFillOn               = False
    res@cnNoDataLabelOn        = False

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
;   prcl = decimalPlaces(pcl,1,True)
;   res@gsnRightString         = "%>0.1="+sprintf("%5.1f",prcl) ;+"~C~%>0.5="+prcm
;   res@gsnRightStringFontHeightF = 0.015
    res@gsnRightString         = ""

    if ( nval.eq.0 ) then
      res@gsnCenterString  = ilab+" "+spc_t+" (n="+nval+", p~B~0.1~N~="+plab+")"
    else
      res@gsnCenterString  = ilab+" "+spc_t+" (n="+nval+", p~B~0.1~N~="+sprintf("%5.1f",plab)+"%)"
    end if

;   res@gsnCenterString        = spc_t
    res@mpDataBaseVersion    = "HighRes"

    res@cnLevelSelectionMode   = "ExplicitLevels"
;   res@cnConstFLabelFormat    = "0f1"
    levels = (/.1,.2,.3,.4,.5,.6,.7,.8,.9,1.0/)
    res@cnLevels = levels 
    cmap = read_colormap_file("WhiteBlueGreenYellowRed")
    res@cnFillPalette = cmap

    if ( drawPoints.eq.False ) then
      plot(n) = gsn_csm_contour_map(wks,ei,res)
    end if

  ;********************************
  ; plot original data
  ;********************************
    if ( drawPoints.eq.True ) then 
      polyres                   = True
      polyres@gsMarkerIndex     = 16          ; polymarker style
      polyres@gsMarkerSizeF     = 1.4         ; polymarker size

      plot(n) = gsn_csm_contour_map_ce(wks,ei,res)
      dumP(n) = gsn_add_polymarker(wks,plot(n),ilon(:),ilat(:),polyres)
    end if
  end do

  ;---------------------------------------------
  ; create panel
  ;---------------------------------------------
  pres                  = True
  pres@gsnPanelLabelBar = True
  pres@lbOrientation =   "vertical"
  pres@lbLabelFontHeightF   = 0.01
  pres@lbTitleFontHeightF   = 0.01             ; make title smaller
  pres@lbTitleString    = "EI (#)"
  pres@lbTitlePosition      = "Top"
  pres@lbLabelStrings       = sprintf("%3.1f",levels)   ; Format the labels
  pres@gsnMaximize = True
  pres@gsnPanelRight  = 0.97
  pres@gsnScale = True

  gsn_panel(wks,plot,(/3,3/),pres)
  trimPNG(outim+"."+formo)

end
