function [ppos31, flag_data_min] = getOptimumPpos31()

ppos31 = [36 54 77 143 240 251 373 384 442 528 634 665 704 761 871 896 905 984 1047 1151 1282 1335 1404 1450 1659 1680 1884 1890 1896 2013 2019;25 30 44 57 158 432 549 604 653 701 750 838 891 955 1009 1153 1222 1298 1428 1522 1533 1581 1590 1613 1682 1716 1720 1752 1906 2046 2048;208 254 281 412 452 491 535 555 615 651 678 729 782 947 963 1029 1120 1323 1331 1333 1429 1477 1582 1609 1668 1706 1736 1800 1854 1991 1999;76 175 287 298 305 349 563 608 611 719 814 881 962 1006 1014 1048 1130 1195 1207 1525 1568 1601 1773 1778 1805 1874 1923 1924 1979 2021 2034;13 85 104 261 326 457 522 668 939 950 969 993 1025 1090 1138 1189 1203 1236 1243 1401 1463 1465 1486 1605 1631 1727 1893 1941 2004 2005 2016;12 83 107 188 198 234 272 347 370 377 437 642 664 720 736 772 794 807 1107 1115 1208 1219 1264 1278 1493 1495 1622 1797 1833 1872 2033;61 160 199 258 348 450 460 546 847 865 907 925 931 1024 1141 1143 1221 1240 1253 1352 1470 1509 1524 1543 1580 1585 1685 1835 1857 1959 2007;19 118 142 250 381 434 501 506 544 582 637 648 692 731 818 824 846 909 957 977 1118 1212 1273 1448 1505 1634 1738 1791 1827 1839 1967;71 97 129 170 289 337 346 355 474 587 884 930 1027 1087 1106 1114 1225 1228 1478 1488 1499 1546 1591 1642 1663 1712 1879 1934 1946 1965 2035;140 153 161 324 340 357 410 441 461 520 647 746 890 922 923 978 990 996 1043 1142 1213 1268 1399 1559 1602 1611 1698 1719 1751 1775 1796];

load('flag_dataK10_Np31.mat');
