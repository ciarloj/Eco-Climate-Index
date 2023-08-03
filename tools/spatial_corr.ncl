begin
  ;; spatial correlation info: 
  ;; https://www.ncl.ucar.edu/Document/Functions/Contributed/pattern_cor.shtml
  ;; t-test info (in example):
  ;; https://www.ncl.ucar.edu/Document/Functions/Built-in/escorc.shtml

  ;*************************
  ; read in data
  ;*************************

  obs = getenv("nam")   ;"EOBS-010-v25e"
  yrs = getenv("years") ;"1995-2014"

  hdir="/home/netapp-clima-scratch/jciarlo/paleosim/"
  ddir=hdir+"data/OBS/"+obs+"/index/"

  v1 = getenv("v1") ;"tas"
  v2 = getenv("v2") ;"tasmax"
  idx1 = getenv("idx1") ;"hwfi"
  idx2 = getenv("idx2") ;"tasmaxmean"

  fil1 = getenv("fil1") ;ddir+v1+"_"+idx1+"_"+obs+"_"+yrs+".nc"
  fil2 = getenv("fil2") ;ddir+v2+"_"+idx2+"_"+obs+"_"+yrs+".nc"

  a1 = addfile(fil1,"r")
  a2 = addfile(fil2,"r")

  var1 = idx1
  var2 = idx2
  if ( idx1.eq."popden" ) then
    var1 = "Population Density, v4.11 (2000, 2005, 2010, 2015, 2020): 2.5 arc-minutes"
  end if
  if ( idx2.eq."popden" ) then
    var2 = "Population Density, v4.11 (2000, 2005, 2010, 2015, 2020): 2.5 arc-minutes"
  end if

  d1 = a1->$var1$
  d2 = a2->$var2$
  if ( idx1.ne."orog" ) then
    d1 := d1(0,:,:)
  end if
  if ( idx2.ne."orog" ) then
    d2 := d2(0,:,:)
  end if

  rc = pattern_cor(d1,d2,1.0,0)
  ;print(rc)

  dims = dimsizes(d1)
  n = dims(0)*dims(1)
  df = n-2
  dn = 1-rc^2
  if ( dn.ne.0 ) then
    t    = rc*sqrt((df)/(1-rc^2))
    p    = student_t(t, df)
  else
    p = 999
  end if
  ;print(p)

  print(idx1+" "+idx2+" "+rc+" "+p)

end

