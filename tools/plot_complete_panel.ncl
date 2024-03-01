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
  outim = idir+"complete_"+dnam+"_"+onam+"_"+spc+"_"+yrs+"_panel"
  formo = "png"
  imgres = 1500
  formo@wkWidth = imgres
  formo@wkHeight = imgres
  wks   = gsn_open_wks (formo,outim)             ; send graphics to PNG file

  spcc  = str_split(spc,"-")
  spc_t = str_capital(spcc(0))+" "+spcc(1)
  print("preparing "+spc_t+" (nboot="+nboot+")")

  varlist = asciiread(slog,1,"string")
; vars  = str_split(varlist," ")
; nvar  = dimsizes(vars)
; vars := vars(3:nvar-1)
  vars := (/"cdd","prsum","rx1day","cwfi","tasmean","hwfi","windmean","orog","op","bc","EI"/)
  nvar := dimsizes(vars)

  plot = new(nvar,graphic)
  dumP = new(nvar,graphic)

  do n=0 , nvar-1

    varl = vars(n)
    if ( varl.eq."EI" .or. varl.eq."op" ) then 
      var = "EcoIndex"
      if ( varl.eq."EI" ) then
        varp = var
      else
        varp = "observation points"
      end if
    else
      var  = varl
      varp = var 
    end if
    if ( varl.eq."bc" ) then
      varp = "bar chart"
      var  = "EcoIndex"
    end if
    print("..."+varp+"...")

    ddir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/boot_"+nboot+"/ndis/"
    dfil = ddir+var+"_"+dnam+"_"+onam+"_"+spc+"_"+yrs+".nc" 
    f = addfile(dfil, "r")
    cdimz = dimsizes(dimsizes(f->comp))
    if ( cdimz.eq.2 ) then
      vi = f->comp(:,:)
    else if ( cdimz.eq.3 ) then
      vi = f->comp(0,:,:)
    else if ( cdimz.eq.4 ) then
      vi = f->comp(0,0,:,:)
    end if
    end if
    end if

    if ( varl.eq."op" ) then
      vi = vi-vi
    end if

    ;;; extract station data for plotting
    ldir = hdir+"/data/"+dtyp+"/"+dnam+"/index/"+onam+"/"
    lfil = ldir+spc+"_"+onam+"_"+dnam+".log"

    ;; extract data from log file
    nrows = numAsciiRow(lfil)
    lines := asciiread(lfil,(/nrows/),"string")
    heads := lines(0)
    lines := lines(1:nrows-1)

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
    nval = num(.not.ismissing(ilon))
    if ( varl.eq."EI" ) then
      th1 = 0.1
      ilon = where(evals.lt.th1,ilon,ilon@_FillValue)
      ilat = where(evals.lt.th1,ilat,ilat@_FillValue)
      nmis = num(.not.ismissing(ilon))
      if ( nval.eq.0 ) then
        npct = 0.0
      else
        npct = nmis*100/nval
      end if
    end if 
    if ( varl.eq."bc" ) then
       barx = (/1,2,3,4,5,6,7,8,9,10,11/)
       barv = (/"miss.","0.1","0.2","0.3","0.4","0.5","0.6","0.7","0.8","0.9","1.0"/)
       dimb = dimsizes(barv)
       bare = new((/dimb/),"integer")
       bare(0) = num(ismissing(ilon))
       bare(1) = num(evals.lt.stringtofloat(barv(1)))
       do b=2 , dimb-2 
         bare(b) = num(evals.lt.stringtofloat(barv(b)) .and. evals.ge.stringtofloat(barv(b-1)))
       end do
       bare(dimb-1) = num(evals.ge.stringtofloat(barv(dimb-2)))
    end if

    if ( varl.ne."bc" ) then
      if ( tdim.eq."2d" ) then
        if ( dtyp .eq. "CPMs" ) then
          xlat = f->xlat
          xlon = f->xlon
        else
          xlat = f->lat
          xlon = f->lon
        end if
;       rpol := f->rotated_pole ;rotated_latitude_longitude
        plat = 48.  ;rpol@grid_north_pole_latitude
        plon = 9.75 ;rpol@grid_north_pole_longitude

        vi@lat2d = xlat
        vi@lon2d = xlon
        dims = dimsizes(xlat)
        nlat = dims(0)
        nlon = dims(1)
      end if
      if ( tdim.eq."1d" ) then
        xlat = f->latitude
        xlon = f->longitude
;       xlon = where(xlon.lt.0,xlon+360,xlon)
        nlat = dimsizes(xlat)
        nlon = dimsizes(xlon)
        vi@lat = xlat
        vi@lon = xlon
      end if
    end if

    ;***********************
    ; plot
    ;***********************
    
    res  = True
    res@gsnDraw             = False
    res@gsnFrame            = False            

    if ( varl.ne."bc" ) then
      res@mpLimitMode       = "Corners"            ; choose range of map
      res@tfDoNDCOverlay         = True      ; do not transform
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
        res@mpLeftCornerLatF  = xlat(0,0) + dllat
        res@mpLeftCornerLonF  = xlon(0,0) + dllon
        res@mpRightCornerLatF = xlat(nlat-1,nlon-1) + drlat
        res@mpRightCornerLonF = xlon(nlat-1,nlon-1) + drlon
        res@mpCenterLonF = xlon(nlat/2,nlon/2) + dlon
        res@mpCenterLatF = xlat(nlat/2,nlon/2) + dlat
      end if
      if ( tdim.eq."1d" ) then
        res@mpLeftCornerLatF  = min(xlat)
        res@mpLeftCornerLonF  = min(xlon)
        res@mpRightCornerLatF = max(xlat)
        res@mpRightCornerLonF = max(xlon)
      end if

    ; usually, when data is placed onto a map, it is TRANSFORMED to the specified
    ; projection. Since this model is already on a native lambert conformal grid,
    ; we want to turn OFF the tranformation.

      colrange = "WhiteBlueGreenYellowRed"
      levels = (/.1,.2,.3,.4,.5,.6,.7,.8,.9,1.0/)
      res@cnNoDataLabelOn = False
      res@cnConstFLabelOn = False
      if ( varl.ne."bc" ) then
        res@cnFillOn               = True      ; color plot desired
        res@cnFillMode             = "RasterFill"
        res@cnLinesOn              = False       ; no contour lines
        res@cnLineLabelsOn         = False       ; no contour line labels
        res@lbLabelBarOn           = False
        res@cnLevelSelectionMode   = "ExplicitLevels"
        res@cnLevels = levels
        cmap = read_colormap_file(colrange)
;       cmap = cmap(::-1,:) ; reverse the color map
        res@cnFillPalette = cmap
      end if

      res@mpFillOn               = False
      res@mpGeophysicalLineColor = "black"     ; color of continental outlines
      res@mpPerimOn              = True      ; draw box around map
      res@mpGridLineDashPattern  = 5         ; lat/lon lines as dashed
      res@mpGridAndLimbOn        = False               ; turn on grid lines
      res@mpDataBaseVersion    = "HighRes"

      res@tmYROn = False            ; Turn off right tickmarks.
      res@tmXTOn = False            ; Turn off top tickmarks.
      res@tmYLOn = False
      res@tmXBOn = False
    end if

    res@gsnLeftString          = "" 
    res@gsnRightString         = ""
    res@gsnRightStringFontHeightF = 0.013
    res@gsnCenterString        = var
    res@gsnCenterStringOrthogonalPosF =  0.02
    if ( varl.eq."EI" ) then
      res@gsnCenterString      = "EI (m~B~0.1~N~="+nmis+": p~B~0.1~N~="+sprintf("%5.1f",npct)+"%)"
    end if
    if ( varl.eq."op" ) then
      res@gsnCenterString      = onam+" (n="+nval+")"
    end if
    if ( varl.eq."bc" ) then
      res@gsnCenterString      = "EI Distribution"
      res@gsnCenterStringOrthogonalPosF = 0.01
    end if
    res@gsnCenterStringFontHeightF = 0.020

    if ( varl.eq."EI" .or. varl.eq."op" ) then
      polyres                   = True
      polyres@gsMarkerIndex     = 16          ; polymarker style
      polyres@gsMarkerSizeF     = 1.2         ; polymarker size
      polyres@gsMarkerColor     = 1

      plot(n) = gsn_csm_contour_map_ce(wks,vi,res)
      dumP(n) = gsn_add_polymarker(wks,plot(n),ilon(:),ilat(:),polyres)
    else if ( varl.eq."bc" ) then
      ;; plot bar graph
      res@vpHeightF = 0.37        ; Changes the aspect ratio
      if ( dtyp .eq. "OBS" ) then
        res@vpWidthF  = 0.68
      end if
      if ( dtyp .eq. "RCMs" ) then
        res@vpWidthF  = 0.42
      end if
      if ( dtyp .eq. "CPMs" ) then
        res@vpWidthF  = 0.6
        res@vpHeightF = 0.3
      end if
      res@tmYROn = False            ; Turn off right tickmarks.
      res@tmXTOn = False            ; Turn off top tickmarks.

      res@tiYAxisString = "quantity (#)"
      res@tiXAxisString = "EI (#)"

      ;---Create color array to hold a bar color for each Y value.
      colors = new(dimb,integer)
      rcol = span_color_rgba(colrange,11)
      rcol(0,0:2) = 0.5
      rcol(1:dimb-1,:) = span_color_rgba(colrange,10)
      res@gsnXYBarChartColors2  = rcol
      res@tmXBMode              = "Explicit"
      res@tmXBValues            = barx
      res@tmXBLabels            = barv
      res@trXMinF      = 0
      res@gsnYRefLine  = 0

      res@gsnXYBarChart = True            ; Create bar plot
      plot(n) = gsn_csm_xy (wks,barx,bare,res)
    else
      plot(n) = gsn_csm_contour_map(wks,vi,res)
    end if
    end if
    delete(res)

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
  pres@lbLabelStrings       = sprintf("%3.1f",levels)   ; Format the labels
  pres@gsnMaximize = True
  pres@gsnPanelRight  = 0.97
  pres@gsnScale = True
  pres@gsnPanelMainString = spc_t
  pres@gsnPanelRowSpec = True

  gsn_panel(wks,plot,(/3,3,3,2/),pres)
  trimPNG(outim+"."+formo)

end
