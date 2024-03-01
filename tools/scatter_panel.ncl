load "/home/netapp-clima/users/jciarlo/records-tool/tools/trimPNG.ncl"

begin

  ;; input parameters
  odir = getenv("odir")
  spc  = getenv("spc")
  onam = getenv("onam")
  dnam = getenv("dnam")
  flog = getenv("flog")

; indxs = (/"cdd","r99","prsum","tasp10","tasp90","tasmean","windmean","orog"/)
; indxs = (/"cdd","r99","prsum","r10mm","r20mm","rx1day","rx5day","nrx5day","tasmean","tasp10","tasp90","tx10p","tx90p","cwfi","hwfi","windmean","orog"/)
  indxs = (/"cdd","rx1day","prsum","tasmean","cwfi","hwfi","windmean","orog"/)
  nindx = dimsizes(indxs)
  img_base = 2500
  img_fact = 500
  imgres = max((/img_base,img_fact*nindx/))

  ;; prepare output
  outn  = "/"+spc+"_"+onam+"_"+dnam+"_scatter_panel"
  form  = "png"
  form@wkWidth = imgres
  form@wkHeight = imgres
  wks   = gsn_open_wks(form,odir+outn)
  print("preparing image w/res: "+imgres+"x"+imgres)

  ;; extract data from log file
  nrows = numAsciiRow(flog)
  lines := asciiread(flog,(/nrows/),"string")
  heads := lines(0)
  lines := lines(1:nrows-1)

  titles = str_split(heads," ")
  ntitls = dimsizes(titles)

  nvs   = new(nindx, "integer")
  ivals = new((/nindx,nrows-1/),"float")

  do i=0, nindx-1
    indx = indxs(i)
    do j=0, ntitls-1 
      title = titles(j)
      if ( indx.eq.title ) then
        nvs(i) = j
        break
      end if
    end do
    nv = nvs(i)
    
    vals = new((/nrows-1/),"float")
    do n=0 , nrows-2
      lsplt = tofloat(str_split(lines(n)," "))
      vals(n) = lsplt(nv)
    end do
    ivals(i,:) = vals(:)
    delete(vals)
  end do 

  plots = new(nindx*nindx, graphic)
  dum = new(nindx*nindx, graphic)
  r2s = new(nindx*nindx,float)

  n = 0
  do i=0, nindx-1
    y = ivals(i,:)
    ynam = indxs(i)
    ymin = min(y)
    ymax = max(y)   

    do j=0, nindx-1
      x = ivals(j,:)
      xnam = indxs(j)
      xmin = min(x)
      xmax = max(x)
      if ( ynam.eq.xnam ) then
        ipdf = pdfx(x,0,False)

        res                     = True                   ; plot mods desired
        res@gsnDraw  = False                          ; don't draw
        res@gsnFrame = False                          ; don't advance frame
        res@gsnMaximize         = True                   ; maximize plot in frame
        res@xyMarkLineModes    := (/"Lines"/)  ; choose which have markers
        res@xyMarkers           = 16                     ; choose type of marker
        res@xyMarkerColor       = "red"                  ; Marker color
        res@xyMarkerSizeF       = 0.004                  ; Marker size (default 0.01)
        res@xyDashPatterns      = 0                      ; solid line
        res@xyLineThicknessF    = 2                      ; set second line to 2
        res@tiXAxisString       = xnam
        res@tiYAxisString       = ynam+" PDF(%)"
        res@trXMinF = ymin
        res@trXMaxF = ymax

        plots(n)  = gsn_csm_xy (wks,ipdf@bin_center,ipdf,res)        ; create plot

      else  

        rc = regline(x,y)
        data = new ( (/2,nrows-1/), typeof(y))  
        data(0,:) = y
      ; y = mx+b 
      ; m is the slope:       rc      returned from regline
      ; b is the y intercept: rc@yave attribute of rc returned from regline
        data(1,:) = rc*(x-rc@xave) + rc@yave 
        rcs = regline_stats(x,y)
        r2s(n) = rcs@r*rcs@r  ;; r2 for linear regression

        res                     = True                   ; plot mods desired
        res@gsnDraw  = False                          ; don't draw
        res@gsnFrame = False                          ; don't advance frame
        res@gsnMaximize         = True                   ; maximize plot in frame
        res@xyMarkLineModes    := (/"Markers","Lines"/)  ; choose which have markers
        res@xyMarkers           = 16                     ; choose type of marker 
        if ( r2s(n).gt.0.49 ) then
          res@xyMarkerColor       = "red"                ; Marker color
        else
          res@xyMarkerColor       = "blue"
        end if
        res@xyMarkerSizeF       = 0.004                  ; Marker size (default 0.01)
        res@xyDashPatterns      = 1                      ; solid line 
        res@xyLineThicknesses  := (/1,1/)                ; set second line to 2
        res@tiXAxisString        = xnam
        res@tiYAxisString        = ynam
        res@trXMinF           = xmin
        res@trXMaxF           = xmax
        res@trYMinF           = ymin
        res@trYMaxF           = ymax

        plots(n)  = gsn_csm_xy (wks,x,data,res)        ; create plot

        ;*****************************************************
        ; Manually create and attach legend
        ;*****************************************************
        res_text                = True              ; text mods desired
        res_text@txFontHeightF  = 0.018             ; change text size
        res_text@txJust         = "CenterLeft"      ; text justification

        xT =  xmin+0.7*(xmax-xmin)
        yN  = ymin+0.9*(ymax-ymin)
        rlab = "R~S~2~N~ = "+r2s(n)
        dum(n) = gsn_add_text(wks,plots(n),rlab,xT,yN,res_text)
        
      end if

      delete(res)
      n = n+1

    end do
  end do

  ;************************************************
  ; create panel
  ;************************************************
  resP = True
  resP@gsnPanelLeft = 0.01
  gsn_panel(wks,plots,(/nindx,nindx/),False)             ; now draw as one plot

; print("saved "+odir+outn+"."+form)
  trimPNG(odir+outn+"."+form)

end
