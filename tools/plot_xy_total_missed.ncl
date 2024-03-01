; ***********************************************
load "tools/trimPNG.ncl"
begin
;************************************************
; read in data
;************************************************
 eobm = (/ 19.,   6.,  0, 21., 20., 19.,   4.,    4./) ; % missed
 eobt = (/ 659, 2006,  0, 412, 116, 259, 3645, 4948./) ; total data (excluding missing)
 rcmm = (/ 23.,   5., 34,  33,  27,  18,    8,   12./) ; % missed 
 rcmt = (/ 778, 2884, 26, 565, 143, 386, 4752, 5379./) ; total data (excluding missing)
 cpmm = (/   9,   7., 42,  25,  27,  23,    6,    4./) ; % missed
 cpmt = (/ 778, 2520, 26, 520, 143, 281, 4391, 3891./) ; total data (excluding missing)
 nspc = dimsizes(eobm)

 misd = new((/3,nspc/),typeof(eobm))
 totd = misd

 misd(0,:) = eobm
 misd(1,:) = rcmm
 misd(2,:) = cpmm

 totd(0,:) = eobt
 totd(1,:) = rcmt
 totd(2,:) = cpmt

 misd = where(totd.eq.0,misd@_FillValue,misd)

;************************************************
; plotting parameters
;************************************************
 hdir  = "/home/netapp-clima-scratch/jciarlo/paleosim"
 idir  = hdir+"/images/"
 outim = idir+"xy_total_missed"
 formo = "png"
;imgres = 1500
;formo@wkWidth = imgres
;formo@wkHeight = imgres
 wks   = gsn_open_wks (formo,outim)             ; send graphics to PNG file

 res                   = True                     ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame
;res@tiMainString      = "Scatter Plot"           ; add title
 res@tmYROn = False            ; Turn off right tickmarks.
 res@tmXTOn = False            ; Turn off top tickmarks.
 res@tiYAxisString = "missed points, p~B~0.1~N~ (%)"
 res@tiXAxisString = "total points, n (#)"
 res@xyMarkLineMode    = "Markers"                ; choose which have markers
 res@xyMarkers         = (/16,16,16/)             ; choose type of marker  
 res@xyMarkerColors    = (/"black","red","blue"/) ; Marker color
 res@xyMarkerSizeF     = 0.01                     ; Marker size (default 0.01)

 res@tmLabelAutoStride = True                     ; nice tick mark labels

 plot  = gsn_csm_xy (wks,totd,misd,res) ; create plot

 ;*****************************************************
 ; Manually create and attach legend
 ;*****************************************************
 res_text                = True              ; text mods desired
 res_text@txFontHeightF  = 0.018             ; change text size
 res_text@txJust         = "CenterLeft"      ; text justification

 xT =  4200
 yN  = 47
 lab = "OBS"
 dum1 = gsn_add_text(wks,plot,lab,xT,yN,res_text)

 dy = 3
 res_text@txFontColor = "red"
 yN  = yN-dy
 lab = "RCM 12.5 km"
 dum2 = gsn_add_text(wks,plot,lab,xT,yN,res_text)

 res_text@txFontColor = "blue"
 yN  = yN-dy
 lab = "CPM  3.5 km"
 dum3 = gsn_add_text(wks,plot,lab,xT,yN,res_text)

 draw(wks)
 frame(wks)
 trimPNG(outim+"."+formo)

end
