; ***********************************************
load "tools/trimPNG.ncl"
begin
;************************************************
; read in data
;************************************************
 eobm = (/ 19.1,  6.8,  0, 21.1, 20.9, 19.7,  4.5,   4.3/) ; % missed
 eobt = (/  658, 2006,  0,  412,  115,  259, 3644, 4947./) ; total data (excluding missing)
 rcmm = (/ 23.8,  5.9, 32,   33, 28.2, 18.7,  8.8,  12.6/) ; % missed 
 rcmt = (/  777, 2883, 25,  564,  142,  386, 4751, 5378./) ; total data (excluding missing)
 cpmm = (/  9.9,  7.2, 44, 25.8, 27.5, 23.8,  6.4,   4.4/) ; % missed
 cpmt = (/  777, 2519, 25,  519,  142,  281, 4390, 3890./) ; total data (excluding missing)
 nspc = dimsizes(eobm)
 spcl = (/"A. decolor","A. lobata","B. megacephalus","P. celina","S. variolosus","S. nigra","S. pandurus","X. violacea"/)

 misd = new((/3,nspc/),typeof(eobm))
 misn = misd
 totd = misd
 totn = misd

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

 markers = (/12, 15, 14, 11, 10, 9, 6, 4/)
 colours = (/"black","red","blue"/)

 res                   = True                     ; plot mods desired
 res@gsnDraw  = False                          ; don't draw
 res@gsnFrame = False                          ; don't advance frame
;res@tiMainString      = "Scatter Plot"           ; add title
 res@tmYROn = False            ; Turn off right tickmarks.
 res@tmXTOn = False            ; Turn off top tickmarks.
 res@tiYAxisString = "p~B~0.1~N~ (%)"
 res@tiXAxisString = "n (#)"
 res@xyMarkLineMode    = "Markers"                ; choose which have markers
 res@xyMarker          = markers(0)               ; choose type of marker  
 res@xyMarkerColors    = colours                  ; Marker color
 res@xyMarkerSizeF     = 0.01                     ; Marker size (default 0.01)
 res@xyMarkerThicknessF = 3.
 res@trXMinF = 0.
 res@trXMaxF = 6000.
 res@trYMinF = 0.
 res@trYMaxF = 50.

 res@tmLabelAutoStride = True                     ; nice tick mark labels

 totn(:,0) = totd(:,0)
 misn(:,0) = misd(:,0)
 plot  = gsn_csm_xy (wks,totn,misn,res) ; create plot

 ;*****************************************************
 ; add remaining points with different markers
 ;*****************************************************
 dumm = new((/nspc,3/),graphic)
 res_mark                = True
 res_mark@gsMarkerSizeF  = 0.01
 res_mark@gsMarkerThicknessF = 3.

 do n = 1, nspc-1
   res_mark@gsMarkerIndex  = markers(n)
   do c = 0, 2
     res_mark@gsMarkerColor = colours(c)
     tot1 = totd(c,n)
     mis1 = misd(c,n) 
     dumm(n,c) = gsn_add_polymarker(wks,plot,tot1,mis1,res_mark) 
   end do
 end do

 ;*****************************************************
 ; Manually create and attach legend
 ;*****************************************************
 res_text                = True              ; text mods desired
 res_text@txFontHeightF  = 0.014             ; change text size
 res_text@txJust         = "CenterLeft"      ; text justification

 xT =  4200.
 yN  = 47.
 lab = "OBS"
 dum1 = gsn_add_text(wks,plot,lab,xT,yN,res_text)

 dx = 200.
 dy = 2.2
 res_text@txFontColor = "red"
 yN  = yN-dy
 lab = "RCM 12.5 km"
 dum2 = gsn_add_text(wks,plot,lab,xT,yN,res_text)

 res_text@txFontColor = "blue"
 yN  = yN-dy
 lab = "CPM  3.5 km"
 dum3 = gsn_add_text(wks,plot,lab,xT,yN,res_text)

 res_text@txFontColor = "black"
 res_mark@gsMarkerColor = colours(0)
 res_mark@gsMarkerIndex = markers(0)
 yN = yN-(1.5*dy)
 dum4  = gsn_add_text(wks,plot,spcl(0),xT,yN,res_text)
 dum4m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)
 yN = yN-dy
 res_mark@gsMarkerIndex = markers(1)
 dum5  = gsn_add_text(wks,plot,spcl(1),xT,yN,res_text)
 dum5m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)
 yN = yN-dy
 res_mark@gsMarkerIndex = markers(2)
 dum6  = gsn_add_text(wks,plot,spcl(2),xT,yN,res_text)
 dum6m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)
 yN = yN-dy
 res_mark@gsMarkerIndex = markers(3)
 dum7  = gsn_add_text(wks,plot,spcl(3),xT,yN,res_text)
 dum7m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)
 yN = yN-dy
 res_mark@gsMarkerIndex = markers(4)
 dum8  = gsn_add_text(wks,plot,spcl(4),xT,yN,res_text)
 dum8m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)
 yN = yN-dy
 res_mark@gsMarkerIndex = markers(5)
 dum9  = gsn_add_text(wks,plot,spcl(5),xT,yN,res_text)
 dum9m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)
 yN = yN-dy
 res_mark@gsMarkerIndex = markers(6)
 dum10  = gsn_add_text(wks,plot,spcl(6),xT,yN,res_text)
 dum10m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)
 yN = yN-dy
 res_mark@gsMarkerIndex = markers(7)
 dum11  = gsn_add_text(wks,plot,spcl(7),xT,yN,res_text)
 dum11m = gsn_add_polymarker(wks,plot,(xT-dx),yN,res_mark)

 draw(wks)
 frame(wks)
 trimPNG(outim+"."+formo)

end
