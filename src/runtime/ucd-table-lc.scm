#| -*-Scheme-*-

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
    2017 Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; UCD property: lc (lower-case)

;;; Generated from Unicode 9.0.0

(declare (usual-integrations))

(define (ucd-lc-value char)
  (or (let ((sv (char->integer char)))
        (vector-ref ucd-lc-table-5 (bytevector-u16be-ref ucd-lc-table-4 (fix:lsh (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-3 (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-2 (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-1 (fix:or (fix:lsh (bytevector-u8-ref ucd-lc-table-0 (fix:lsh sv -16)) 4) (fix:and 15 (fix:lsh sv -12)))) 4) (fix:and 15 (fix:lsh sv -8)))) 4) (fix:and 15 (fix:lsh sv -4)))) 4) (fix:and 15 sv)) 1))))
      (string char)))

(define-deferred ucd-lc-table-0
  (apply bytevector '(0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2)))

(define-deferred ucd-lc-table-1
  (apply bytevector '(0 1 2 3 3 3 3 3 3 3 4 3 3 3 3 5 6 7 3 3 3 3 3 3 3 3 3 3 3 3 8 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3)))

(define-deferred ucd-lc-table-2
  (apply bytevector '(0 1 2 3 4 5 6 6 6 6 6 6 6 6 6 6 7 6 6 8 6 6 6 6 6 6 6 6 6 6 9 10 6 11 6 6 12 6 6 6 6 6 6 6 13 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 14 15 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 16 6 6 6 6 17 6 6 6 6 6 6 6 18 6 6 6 6 6 6 6 6 6 6 6 19 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 20 6 6 6 6 6 6)))

(define-deferred ucd-lc-table-3
  (apply bytevector '(0 0 0 0 1 2 0 0 0 0 0 0 3 4 0 0 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 26 27 28 29 0 30 31 32 33 34 35 36 0 0 0 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 53 54 55 0 0 0 0 0 0 0 0 0 0 0 0 0 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 0 85 86 87 88 89 90 91 92 0 0 93 94 0 0 95 0 96 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 97 98 0 0 0 99 100 101 0 0 0 102 103 104 105 106 107 108 109 110 111 0 0 0 0 112 113 114 0 115 116 0 0 0 0 0 0 0 0 117 118 119 120 121 122 123 124 125 126 0 0 0 0 0 0 127 128 0 0 0 0 0 0 0 0 0 0 0 0 129 130 131 0 0 0 0 0 0 0 0 132 133 134 0 0 0 0 0 0 0 0 0 0 135 136 137 138 0 0 0 0 0 0 0 0 0 0 0 0 0 0 139 140 0 0 0 0 141 142 143 0 0 0 0 0 0 0 0 0 0 0 0 0)))

(define-deferred ucd-lc-table-4
  (apply
   bytevector-u16be
   '(0    0    0    0    0    0   0    0    0    0    0    0   0    0    0    0    0    1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   0    0    0    0    0    27   28   29   30   31   32   33   34   35   36   37   38   39   40   41   42   43   44   45   46   47   48   49   0    50   51   52   53   54   55   56   0    57   0    58   0    59   0    60   0    61   0    62   0    63   0    64  0    65  0    66  0    67  0    68   0    69   0    70   0    71   0    72   0    73   0    74   0    75   0    76   0    77   0    78   0    79   0    80   0    81   0    82   0    83   0    84   0    0    85   0   86   0   87   0   88  0   89  0   90  0   91  0    92   0    0    93   0    94   0    95   0    96   0    97   0    98   0    99   0    100  0    101  0    102  0    103  0    104  0    105  0    106  0    107  0    108  0    109  0    110  0    111  0    112  0    113  0    114  0    115  0    116
     117  0    118  0    119  0   0    0    120  121  0    122 0    123  124  0    125  126  127  0    0    128  129  130  131  0    132  133  0    134  135  136  0    0    0    137  138  0    139  140  0    141  0    142  0    143  144  0    145  0    0    146  0    147  148  0    149  150  151  0    152  0    153  154  0    0    0    155  0    0    0    0    0    0    0    156  156  0    157  157  0    158  158  0    159  0    160  0    161  0    162  0    163  0    164 0    165 0    166 0    0   167  0    168  0    169  0    170  0    171  0    172  0    173  0    174  0    175  0    0    176  176  0    177  0    178  179  180  0    181  0    182  0    183  0    184  0    185  0   186  0   187  0   188 0   189 0   190 0   191 0    192  0    193  0    194  0    195  0    196  0    197  0    198  0    199  0    200  0    201  0    202  0    203  0    204  0    205  0    206  0    207  0    208  0    209  0    0    0    0    0    0    0    210  211  0    212  213  0    0    214
     0    215  216  217  218  0   219  0    220  0    221  0   222  0    223  0    224  0    0    0    225  0    0    0    0    0    0    0    0    226  0    0    0    0    0    0    227  0    228  229  230  0    231  0    232  233  0    234  235  236  237  238  239  240  241  242  243  244  245  246  247  248  249  250  0    251  252  253  254  255  256  257  258  259  0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    0    260  0   0    0   0    0   0    0   0    261  0    262  0    263  0    264  0    265  0    266  0    267  0    268  0    269  0    270  0    271  0    272  0    0    0    0    0    241  0    0    273  0    274  275  0    0   276  277 278  279 280 281 282 283 284 285 286 287  288  289  290  291  292  293  294  295  296  297  298  299  300  301  302  303  304  305  306  307  308  309  310  311  312  313  314  315  316  317  318  319  320  321  322  323  324  325  326  327  0    328  0    329  0    330  0    331  0    332
     0    333  0    334  0    335 0    336  0    337  0    338 0    339  0    340  0    341  0    342  0    343  0    0    0    0    0    0    0    0    0    344  0    345  0    346  0    347  0    348  0    349  0    350  0    351  0    352  0    353  0    354  0    355  0    356  0    357  0    358  0    359  0    360  0    361  0    362  0    363  0    364  0    365  0    366  0    367  0    368  0    369  0    370  0    371  372  0    373  0    374  0    375  0    376 0    377 0    378 0    0   379  0    380  0    381  0    382  0    383  0    384  0    385  0    386  0    387  0    388  0    389  0    390  0    391  0    392  0    393  0    394  0    395  0    396  0    397  0   398  0   399  0   400 0   401 0   402 0   403 0    404  0    405  0    406  0    407  0    408  0    409  0    410  0    411  0    412  0    413  0    414  0    415  0    416  0    417  0    418  0    419  0    420  0    421  0    422  0    423  0    424  0    425  0    426  0    0    427  428  429
     430  431  432  433  434  435 436  437  438  439  440  441 442  443  444  445  446  447  448  449  450  451  452  453  454  455  456  457  458  459  460  461  462  463  464  0    0    0    0    0    0    0    0    0    465  466  467  468  469  470  471  472  473  474  475  476  477  478  479  480  481  482  483  484  485  486  487  488  489  490  491  492  493  494  495  496  497  498  499  500  501  502  0    503  0    0    0    0    0    504  0    0    505  506  507 508  509 510  511 512  513 514  515  516  517  518  519  520  521  522  523  524  525  526  527  528  529  530  531  532  533  534  535  536  537  538  539  540  541  542  543  544  545  546  547  548  549  550  551 552  553 554  555 556 557 558 559 560 561 562 563  564  565  566  567  568  569  570  571  572  573  574  575  576  577  578  579  580  581  582  583  584  585  586  587  588  589  590  0    0    0    0    0    0    0    0    0    0    591  0    592  0    593  0    594  0    595  0    596  0    597
     0    598  0    599  0    600 0    601  0    602  0    603 0    604  0    605  0    606  0    607  0    608  0    609  0    610  0    611  0    612  0    613  0    614  0    615  0    616  0    617  0    618  0    619  0    620  0    621  0    622  0    623  0    624  0    625  0    626  0    627  0    628  0    629  0    630  0    631  0    632  0    633  0    634  0    635  0    636  0    637  0    638  0    639  0    640  0    641  0    642  0    643  0    644  0   645  0   646  0   647  0   648  0    649  0    650  0    651  0    652  0    653  0    654  0    655  0    656  0    657  0    658  0    659  0    660  0    661  0    662  0    663  0    664  0    665  0    0    0   0    0   0    0   0   0   666 0   667 0   668 0    669  0    670  0    671  0    672  0    673  0    674  0    675  0    676  0    677  0    678  0    679  0    680  0    681  0    682  0    683  0    684  0    685  0    686  0    687  0    688  0    689  0    690  0    691  0    692  0    693  0
     694  0    695  0    696  0   697  0    698  0    699  0   700  0    701  0    702  0    703  0    704  0    705  0    706  0    707  0    708  0    709  0    710  0    711  0    712  0    713  0    714  0    0    0    0    0    0    0    0    0    715  716  717  718  719  720  721  722  0    0    0    0    0    0    0    0    723  724  725  726  727  728  0    0    0    0    0    0    0    0    0    0    729  730  731  732  733  734  735  736  0    0    0    0    0   0    0   0    737 738  739 740  741  742  743  744  0    0    0    0    0    0    0    0    745  746  747  748  749  750  0    0    0    0    0    0    0    0    0    0    0    751  0    752  0    753  0    754  0   0    0   0    0   0   0   0   755 756 757 758 759  760  761  762  0    0    0    0    0    0    0    0    763  764  765  766  767  768  769  770  0    0    0    0    0    0    0    0    771  772  773  774  775  776  777  778  0    0    0    0    0    0    0    0    779  780  781  782  783  784  785
     786  0    0    0    0    0   0    0    0    787  788  789 790  791  0    0    0    0    0    0    0    0    0    0    0    792  793  794  795  796  0    0    0    0    0    0    0    0    0    0    0    797  798  799  800  0    0    0    0    0    0    0    0    0    0    0    0    801  802  803  804  805  0    0    0    0    0    0    0    0    0    0    0    806  807  808  809  810  0    0    0    0    0    0    0    0    0    257  0    0    0    11   32   0    0   0    0   0    0   811  0   0    0    0    0    0    0    0    0    0    0    0    0    812  813  814  815  816  817  818  819  820  821  822  823  824  825  826  827  0    0    0    828  0    0    0    0    0    0   0    0   0    0   0   0   0   0   0   0   0   0    829  830  831  832  833  834  835  836  837  838  839  840  841  842  843  844  845  846  847  848  849  850  851  852  853  854  855  856  857  858  859  860  861  862  863  864  865  866  867  868  869  870  871  872  873  874  875  876  877  878
     879  880  881  882  883  884 885  886  887  888  889  890 891  892  893  894  895  896  897  898  899  900  901  0    902  0    903  904  905  0    0    906  0    907  0    908  0    909  910  911  912  0    913  0    0    914  0    0    0    0    0    0    0    0    915  916  917  0    918  0    919  0    920  0    921  0    922  0    923  0    924  0    925  0    926  0    927  0    928  0    929  0    930  0    931  0    932  0    933  0    934  0    935  0    936 0    937 0    938 0    939 0    940  0    941  0    942  0    943  0    944  0    945  0    946  0    947  0    948  0    949  0    950  0    951  0    952  0    953  0    954  0    955  0    956  0    957  0    958 0    959 0    960 0   961 0   962 0   963 0   964  0    965  0    966  0    0    0    0    0    0    0    0    967  0    968  0    0    0    0    969  0    0    0    0    0    0    0    0    0    0    0    0    0    970  0    971  0    972  0    973  0    974  0    975  0    976  0    977  0    978
     0    979  0    980  0    981 0    982  0    983  0    984 0    985  0    986  0    987  0    988  0    989  0    990  0    991  0    992  0    0    0    993  0    994  0    995  0    996  0    997  0    998  0    999  0    1000 0    1001 0    1002 0    1003 0    1004 0    1005 0    1006 0    0    0    0    0    0    0    1007 0    1008 0    1009 0    1010 0    1011 0    1012 0    1013 0    0    0    1014 0    1015 0    1016 0    1017 0    1018 0    1019 0    1020 0   1021 0   1022 0   1023 0   1024 0    1025 0    1026 0    1027 0    1028 0    1029 0    1030 0    1031 0    1032 0    1033 0    1034 0    1035 0    1036 0    1037 0    1038 0    1039 0    1040 0    1041 0    1042 0   1043 0   1044 0   0   0   0   0   0   0   0   0    0    1045 0    1046 0    1047 1048 0    1049 0    1050 0    1051 0    1052 0    0    0    0    1053 0    1054 0    0    1055 0    1056 0    0    0    1057 0    1058 0    1059 0    1060 0    1061 0    1062 0    1063 0    1064 0    1065 0    1066 0
     1067 1068 1069 1070 1071 0   1072 1073 1074 1075 1076 0   1077 0    0    0    0    0    0    0    0    0    0    1078 1079 1080 1081 1082 1083 1084 1085 1086 1087 1088 1089 1090 1091 1092 1093 1094 1095 1096 1097 1098 1099 1100 1101 1102 1103 0    0    0    0    0    1104 1105 1106 1107 1108 1109 1110 1111 1112 1113 1114 1115 1116 1117 1118 1119 1120 1121 1122 1123 1124 1125 1126 1127 1128 1129 1130 1131 1132 1133 1134 1135 1136 1137 1138 1139 1140 1141 1142 1143 0   0    0   0    0   0    0   0    1144 1145 1146 1147 1148 1149 1150 1151 1152 1153 1154 1155 1156 1157 1158 1159 1160 1161 1162 1163 1164 1165 1166 1167 1168 1169 1170 1171 1172 1173 1174 1175 1176 1177 1178 1179 0   0    0   0    0   0   0   0   0   0   0   0   1180 1181 1182 1183 1184 1185 1186 1187 1188 1189 1190 1191 1192 1193 1194 1195 1196 1197 1198 1199 1200 1201 1202 1203 1204 1205 1206 1207 1208 1209 1210 1211 1212 1213 1214 1215 1216 1217 1218 1219 1220 1221 1222 1223 1224 1225 1226 1227 1228 1229 1230
     0    0    0    0    0    0   0    0    0    0    0    0   0    1231 1232 1233 1234 1235 1236 1237 1238 1239 1240 1241 1242 1243 1244 1245 1246 1247 1248 1249 1250 1251 1252 1253 1254 1255 1256 1257 1258 1259 1260 1261 1262 1263 1264 1265 1266 1267 1268 1269 1270 1271 1272 1273 1274 1275 1276 1277 1278 1279 1280 1281 1282 1283 1284 1285 1286 1287 1288 1289 1290 1291 1292 1293 1294 1295 1296 0    0    0    0    0    0    0    0    0    0    0    0    0    0)))

(define-deferred ucd-lc-table-5
  (list->vector
   (map
    (lambda (converted)
      (and converted
           (string* (map integer->char converted))))
    '(#f      (97)    (98)    (99)    (100)   (101)   (102)   (103)   (104)   (105)   (106)   (107)   (108)   (109)   (110)   (111)   (112)   (113)   (114)   (115)   (116)   (117)   (118)   (119)   (120)   (121)   (122)   (224)   (225)   (226)   (227)   (228)   (229)   (230)   (231)   (232)   (233)   (234)   (235)   (236)   (237)   (238)   (239)   (240)   (241)   (242)   (243)   (244)   (245)   (246)   (248)   (249)   (250)   (251)   (252)   (253)   (254)   (257)   (259)   (261)   (263)   (265)   (267)   (269)   (271)   (273)   (275)   (277)   (279)   (281)   (283)   (285)   (287)   (289)   (291)   (293)   (295)   (297)   (299)   (301)   (303)   (105 775) (307)   (309)    (311)    (314)    (316)    (318)    (320)    (322)    (324)    (326)    (328)    (331)    (333)    (335)    (337)    (339)    (341)    (343)    (345)    (347)    (349)    (351)    (353)    (355)    (357)    (359)    (361)    (363)    (365)    (367)    (369)    (371)    (373)    (375)    (255)    (378)
      (380)   (382)   (595)   (387)   (389)   (596)   (392)   (598)   (599)   (396)   (477)   (601)   (603)   (402)   (608)   (611)   (617)   (616)   (409)   (623)   (626)   (629)   (417)   (419)   (421)   (640)   (424)   (643)   (429)   (648)   (432)   (650)   (651)   (436)   (438)   (658)   (441)   (445)   (454)   (457)   (460)   (462)   (464)   (466)   (468)   (470)   (472)   (474)   (476)   (479)   (481)   (483)   (485)   (487)   (489)   (491)   (493)   (495)   (499)   (501)   (405)   (447)   (505)   (507)   (509)   (511)   (513)   (515)   (517)   (519)   (521)   (523)   (525)   (527)   (529)   (531)   (533)   (535)   (537)   (539)   (541)   (543)     (414)   (547)    (549)    (551)    (553)    (555)    (557)    (559)    (561)    (563)    (11365)  (572)    (410)    (11366)  (578)    (384)    (649)    (652)    (583)    (585)    (587)    (589)    (591)    (881)    (883)    (887)    (1011)   (940)    (941)    (942)    (943)    (972)    (973)    (974)    (945)    (946)
      (947)   (948)   (949)   (950)   (951)   (952)   (953)   (954)   (955)   (956)   (957)   (958)   (959)   (960)   (961)   (963)   (964)   (965)   (966)   (967)   (968)   (969)   (970)   (971)   (983)   (985)   (987)   (989)   (991)   (993)   (995)   (997)   (999)   (1001)  (1003)  (1005)  (1007)  (1016)  (1010)  (1019)  (891)   (892)   (893)   (1104)  (1105)  (1106)  (1107)  (1108)  (1109)  (1110)  (1111)  (1112)  (1113)  (1114)  (1115)  (1116)  (1117)  (1118)  (1119)  (1072)  (1073)  (1074)  (1075)  (1076)  (1077)  (1078)  (1079)  (1080)  (1081)  (1082)  (1083)  (1084)  (1085)  (1086)  (1087)  (1088)  (1089)  (1090)  (1091)  (1092)  (1093)  (1094)    (1095)  (1096)   (1097)   (1098)   (1099)   (1100)   (1101)   (1102)   (1103)   (1121)   (1123)   (1125)   (1127)   (1129)   (1131)   (1133)   (1135)   (1137)   (1139)   (1141)   (1143)   (1145)   (1147)   (1149)   (1151)   (1153)   (1163)   (1165)   (1167)   (1169)   (1171)   (1173)   (1175)   (1177)   (1179)   (1181)
      (1183)  (1185)  (1187)  (1189)  (1191)  (1193)  (1195)  (1197)  (1199)  (1201)  (1203)  (1205)  (1207)  (1209)  (1211)  (1213)  (1215)  (1231)  (1218)  (1220)  (1222)  (1224)  (1226)  (1228)  (1230)  (1233)  (1235)  (1237)  (1239)  (1241)  (1243)  (1245)  (1247)  (1249)  (1251)  (1253)  (1255)  (1257)  (1259)  (1261)  (1263)  (1265)  (1267)  (1269)  (1271)  (1273)  (1275)  (1277)  (1279)  (1281)  (1283)  (1285)  (1287)  (1289)  (1291)  (1293)  (1295)  (1297)  (1299)  (1301)  (1303)  (1305)  (1307)  (1309)  (1311)  (1313)  (1315)  (1317)  (1319)  (1321)  (1323)  (1325)  (1327)  (1377)  (1378)  (1379)  (1380)  (1381)  (1382)  (1383)  (1384)  (1385)    (1386)  (1387)   (1388)   (1389)   (1390)   (1391)   (1392)   (1393)   (1394)   (1395)   (1396)   (1397)   (1398)   (1399)   (1400)   (1401)   (1402)   (1403)   (1404)   (1405)   (1406)   (1407)   (1408)   (1409)   (1410)   (1411)   (1412)   (1413)   (1414)   (11520)  (11521)  (11522)  (11523)  (11524)  (11525)  (11526)
      (11527) (11528) (11529) (11530) (11531) (11532) (11533) (11534) (11535) (11536) (11537) (11538) (11539) (11540) (11541) (11542) (11543) (11544) (11545) (11546) (11547) (11548) (11549) (11550) (11551) (11552) (11553) (11554) (11555) (11556) (11557) (11559) (11565) (43888) (43889) (43890) (43891) (43892) (43893) (43894) (43895) (43896) (43897) (43898) (43899) (43900) (43901) (43902) (43903) (43904) (43905) (43906) (43907) (43908) (43909) (43910) (43911) (43912) (43913) (43914) (43915) (43916) (43917) (43918) (43919) (43920) (43921) (43922) (43923) (43924) (43925) (43926) (43927) (43928) (43929) (43930) (43931) (43932) (43933) (43934) (43935) (43936)   (43937) (43938)  (43939)  (43940)  (43941)  (43942)  (43943)  (43944)  (43945)  (43946)  (43947)  (43948)  (43949)  (43950)  (43951)  (43952)  (43953)  (43954)  (43955)  (43956)  (43957)  (43958)  (43959)  (43960)  (43961)  (43962)  (43963)  (43964)  (43965)  (43966)  (43967)  (5112)   (5113)   (5114)   (5115)   (5116)
      (5117)  (7681)  (7683)  (7685)  (7687)  (7689)  (7691)  (7693)  (7695)  (7697)  (7699)  (7701)  (7703)  (7705)  (7707)  (7709)  (7711)  (7713)  (7715)  (7717)  (7719)  (7721)  (7723)  (7725)  (7727)  (7729)  (7731)  (7733)  (7735)  (7737)  (7739)  (7741)  (7743)  (7745)  (7747)  (7749)  (7751)  (7753)  (7755)  (7757)  (7759)  (7761)  (7763)  (7765)  (7767)  (7769)  (7771)  (7773)  (7775)  (7777)  (7779)  (7781)  (7783)  (7785)  (7787)  (7789)  (7791)  (7793)  (7795)  (7797)  (7799)  (7801)  (7803)  (7805)  (7807)  (7809)  (7811)  (7813)  (7815)  (7817)  (7819)  (7821)  (7823)  (7825)  (7827)  (7829)  (223)   (7841)  (7843)  (7845)  (7847)  (7849)    (7851)  (7853)   (7855)   (7857)   (7859)   (7861)   (7863)   (7865)   (7867)   (7869)   (7871)   (7873)   (7875)   (7877)   (7879)   (7881)   (7883)   (7885)   (7887)   (7889)   (7891)   (7893)   (7895)   (7897)   (7899)   (7901)   (7903)   (7905)   (7907)   (7909)   (7911)   (7913)   (7915)   (7917)   (7919)   (7921)
      (7923)  (7925)  (7927)  (7929)  (7931)  (7933)  (7935)  (7936)  (7937)  (7938)  (7939)  (7940)  (7941)  (7942)  (7943)  (7952)  (7953)  (7954)  (7955)  (7956)  (7957)  (7968)  (7969)  (7970)  (7971)  (7972)  (7973)  (7974)  (7975)  (7984)  (7985)  (7986)  (7987)  (7988)  (7989)  (7990)  (7991)  (8000)  (8001)  (8002)  (8003)  (8004)  (8005)  (8017)  (8019)  (8021)  (8023)  (8032)  (8033)  (8034)  (8035)  (8036)  (8037)  (8038)  (8039)  (8064)  (8065)  (8066)  (8067)  (8068)  (8069)  (8070)  (8071)  (8080)  (8081)  (8082)  (8083)  (8084)  (8085)  (8086)  (8087)  (8096)  (8097)  (8098)  (8099)  (8100)  (8101)  (8102)  (8103)  (8112)  (8113)  (8048)    (8049)  (8115)   (8050)   (8051)   (8052)   (8053)   (8131)   (8144)   (8145)   (8054)   (8055)   (8160)   (8161)   (8058)   (8059)   (8165)   (8056)   (8057)   (8060)   (8061)   (8179)   (8526)   (8560)   (8561)   (8562)   (8563)   (8564)   (8565)   (8566)   (8567)   (8568)   (8569)   (8570)   (8571)   (8572)   (8573)
      (8574)  (8575)  (8580)  (9424)  (9425)  (9426)  (9427)  (9428)  (9429)  (9430)  (9431)  (9432)  (9433)  (9434)  (9435)  (9436)  (9437)  (9438)  (9439)  (9440)  (9441)  (9442)  (9443)  (9444)  (9445)  (9446)  (9447)  (9448)  (9449)  (11312) (11313) (11314) (11315) (11316) (11317) (11318) (11319) (11320) (11321) (11322) (11323) (11324) (11325) (11326) (11327) (11328) (11329) (11330) (11331) (11332) (11333) (11334) (11335) (11336) (11337) (11338) (11339) (11340) (11341) (11342) (11343) (11344) (11345) (11346) (11347) (11348) (11349) (11350) (11351) (11352) (11353) (11354) (11355) (11356) (11357) (11358) (11361) (619)   (7549)  (637)   (11368) (11370)   (11372) (593)    (625)    (592)    (594)    (11379)  (11382)  (575)    (576)    (11393)  (11395)  (11397)  (11399)  (11401)  (11403)  (11405)  (11407)  (11409)  (11411)  (11413)  (11415)  (11417)  (11419)  (11421)  (11423)  (11425)  (11427)  (11429)  (11431)  (11433)  (11435)  (11437)  (11439)  (11441)  (11443)  (11445)
      (11447) (11449) (11451) (11453) (11455) (11457) (11459) (11461) (11463) (11465) (11467) (11469) (11471) (11473) (11475) (11477) (11479) (11481) (11483) (11485) (11487) (11489) (11491) (11500) (11502) (11507) (42561) (42563) (42565) (42567) (42569) (42571) (42573) (42575) (42577) (42579) (42581) (42583) (42585) (42587) (42589) (42591) (42593) (42595) (42597) (42599) (42601) (42603) (42605) (42625) (42627) (42629) (42631) (42633) (42635) (42637) (42639) (42641) (42643) (42645) (42647) (42649) (42651) (42787) (42789) (42791) (42793) (42795) (42797) (42799) (42803) (42805) (42807) (42809) (42811) (42813) (42815) (42817) (42819) (42821) (42823) (42825)   (42827) (42829)  (42831)  (42833)  (42835)  (42837)  (42839)  (42841)  (42843)  (42845)  (42847)  (42849)  (42851)  (42853)  (42855)  (42857)  (42859)  (42861)  (42863)  (42874)  (42876)  (7545)   (42879)  (42881)  (42883)  (42885)  (42887)  (42892)  (613)    (42897)  (42899)  (42903)  (42905)  (42907)  (42909)  (42911)
      (42913) (42915) (42917) (42919) (42921) (614)   (604)   (609)   (620)   (618)   (670)   (647)   (669)   (43859) (42933) (42935) (65345) (65346) (65347) (65348) (65349) (65350) (65351) (65352) (65353) (65354) (65355) (65356) (65357) (65358) (65359) (65360) (65361) (65362) (65363) (65364) (65365) (65366) (65367) (65368) (65369) (65370) (66600) (66601) (66602) (66603) (66604) (66605) (66606) (66607) (66608) (66609) (66610) (66611) (66612) (66613) (66614) (66615) (66616) (66617) (66618) (66619) (66620) (66621) (66622) (66623) (66624) (66625) (66626) (66627) (66628) (66629) (66630) (66631) (66632) (66633) (66634) (66635) (66636) (66637) (66638) (66639)   (66776) (66777)  (66778)  (66779)  (66780)  (66781)  (66782)  (66783)  (66784)  (66785)  (66786)  (66787)  (66788)  (66789)  (66790)  (66791)  (66792)  (66793)  (66794)  (66795)  (66796)  (66797)  (66798)  (66799)  (66800)  (66801)  (66802)  (66803)  (66804)  (66805)  (66806)  (66807)  (66808)  (66809)  (66810)  (66811)
      (68800) (68801) (68802) (68803) (68804) (68805) (68806) (68807) (68808) (68809) (68810) (68811) (68812) (68813) (68814) (68815) (68816) (68817) (68818) (68819) (68820) (68821) (68822) (68823) (68824) (68825) (68826) (68827) (68828) (68829) (68830) (68831) (68832) (68833) (68834) (68835) (68836) (68837) (68838) (68839) (68840) (68841) (68842) (68843) (68844) (68845) (68846) (68847) (68848) (68849) (68850) (71872) (71873) (71874) (71875) (71876) (71877) (71878) (71879) (71880) (71881) (71882) (71883) (71884) (71885) (71886) (71887) (71888) (71889) (71890) (71891) (71892) (71893) (71894) (71895) (71896) (71897) (71898) (71899) (71900) (71901) (71902)   (71903) (125218) (125219) (125220) (125221) (125222) (125223) (125224) (125225) (125226) (125227) (125228) (125229) (125230) (125231) (125232) (125233) (125234) (125235) (125236) (125237) (125238) (125239) (125240) (125241) (125242) (125243) (125244) (125245) (125246) (125247) (125248) (125249) (125250) (125251)))))
