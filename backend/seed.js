const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const db = new sqlite3.Database('./database.sqlite');
const crypto = require('crypto');

// The raw TSV data pasted from the user
const rawData = `1	A	ACHHRA SAKSHI SUNIL AANCHAL	2024.sakshi.achhra@ves.ac.in	Advanced Data Management Technologies	Batch A 	Charusheela Nehete	Charusheela Nehete
2	A	BADGUJAR PARTH SANJAY JAYSHREE	2024.parth.badgujar@ves.ac.in	Advanced Data Management Technologies	Batch A		
3	A	BAJAJ JATIN LAL VASHDEV MANSI	d2025.jatin.bajaj@ves.ac.in	Advanced Data Management Technologies	Batch A		
4	A	BAJAJ TISHA NARENDRA DIYA	d2025.tisha.bajaj@ves.ac.in	Advanced Data Management Technologies	Batch A		
5	A	BHORE ADITYA SANJAY SAKSHI	2024.aditya.bhore@ves.ac.in	Advanced Data Management Technologies	Batch A		
6	A	CHAVAN PARTH RAMAKANT RASHMI	2024.parth.chavan@ves.ac.in	Advanced Data Management Technologies	Batch A		
7	A	CHAVAN RAJ VALMIK BHAGYASHRI	2024.raj.chavan@ves.ac.in	Advanced Data Management Technologies	Batch A		
8	A	CHAWAN MAANAS VIHANG MAYURI	2024.maanas.chawan@ves.ac.in	Advanced Data Management Technologies	Batch A		
9	A	CHAWLA PRIYANKA MANOJ GEETA	d2025.priyanka.chawla@ves.ac.in	Advanced Data Management Technologies	Batch A		
10	A	DHAMEJA DIVYA SURESH KAJAL	2024.divya.dhameja@ves.ac.in	Advanced Data Management Technologies	Batch A		
11	A	DUSEJA TISHA SURESH KESAR	2024.tisha.duseja@ves.ac.in	Advanced Data Management Technologies	Batch A		
12	A	DYARAM SHRIRAJ PRAMOD SHARADA	2024.shriraj.dyaram@ves.ac.in	Advanced Data Management Technologies	Batch A		
13	A	GADGE ATHARVA AVINASH CHITRA	2024.atharva.gadge@ves.ac.in	Advanced Data Management Technologies	Batch A		
14	A	GAWADE HARSHVARDHAN ADINATH UJWALA	2024.harshvardhan.gawade@ves.ac.in	Advanced Data Management Technologies	Batch A		
15	A	GUPTA SUJAL MANOJ CHANDRAKALA	2024.sujal.gupta@ves.ac.in	Advanced Data Management Technologies	Batch A		
16	A	JITENDRA HET BHANUSHALI SHEETAL	2024.het.bhanushali@ves.ac.in	Advanced Data Management Technologies	Batch A		
17	A	KADAM RANJIT DNYANESHWAR MANISHA	2024.ranjit.kadam@ves.ac.in	Advanced Data Management Technologies	Batch A		
18	A	KARAMCHANDANI DARSHAN UTTAM POOJA	2024.darshan.karamchandani@ves.ac.in	Advanced Data Management Technologies	Batch A		
19	A	KATARIYA ISHAN MANOJ BHAVIKA	2024.ishan.katariya@ves.ac.in	Advanced Data Management Technologies	Batch A		
20	A	KHAIRNAR VIPUL RAOSAHEB SUNANDABAI	2024.vipul.khairanar@ves.ac.in	Advanced Data Management Technologies	Batch A		
21	A	KHEMANI VINEET MANOJ BHAVIKA	d2025.vineet.khemani@ves.ac.in	Advanced Data Management Technologies	Batch A		
22	A	KORDE AKSHAT DATTATRAY JYOTI	d2025.akshat.korde@ves.ac.in	Advanced Data Management Technologies	Batch A		
23	A	KSHIRSAGAR SHIVAM SANDEEP ARCHANA	2024.shivam.kshirsagar@ves.ac.in	Advanced Data Management Technologies	Batch B		Charusheela Nehete
24	A	KUKREJA HARDIK PAWAN NANDINI	d2025.hardik.kukreja@ves.ac.in	Advanced Data Management Technologies	Batch B		
25	A	KUMAR ADITYA ANJANI SHOBHA	2024.aditya.kumar@ves.ac.in	Advanced Data Management Technologies	Batch B		
26	A	MANKAR SWAYAM RAVINDRA SUSHMA	2024.swayam.mankar@ves.ac.in	Advanced Data Management Technologies	Batch B		
27	A	MISHRA ASHUTOSH ARUN NEELAM	2024.ashutosh.mishra@ves.ac.in	Advanced Data Management Technologies	Batch B		
28	A	MISHRA SHIVAM RAMENDRA PRAKASH	2024.shivam.mishra@ves.ac.in	Advanced Data Management Technologies	Batch B		
29	A	MOTWANI VIVEK GIRISH MEENA	2024.vivek.motwani@ves.ac.in	Advanced Data Management Technologies	Batch B		
30	A	MULWANI DHIREN JEETENDER RIA	2024.dhiren.mulwani@ves.ac.in	Advanced Data Management Technologies	Batch B		
31	A	PANDEY SAKSHI MAHENDRA SANJU	2024.sakshi.pandey@ves.ac.in	Advanced Data Management Technologies	Batch B		
32	A	PANJWANI RAM GULSHAN	d2025,ram.panjwani@ves.ac.in	Advanced Data Management Technologies	Batch B		
33	A	PARSEKAR PARTH VAIBHAV ADITI	2024.parth.parsekar@ves.ac.in	Advanced Data Management Technologies	Batch B		
34	A	PATEL DAKSH DHARMENDRA DIMPAL	d2025.daksh.patel@ves.ac.in	Advanced Data Management Technologies	Batch B		
35	A	PATIL SAKSHI SANJAY SONALI	2024.sakshi.patil@ves.ac.in	Advanced Data Management Technologies	Batch B		
36	A	PAWAR TANAYA GANESH SHILPA	2024.tanaya.pawar@ves.ac.in	Advanced Data Management Technologies	Batch B		
37	A	PINJANI HARSH KISHORE MAHEK	2024.harsh.pinjani@ves.ac.in	Advanced Data Management Technologies	Batch B		
38	A	POOJARY SANJOG SUDHAKAR JAYASHREE	2024.sanjog.poojary@ves.ac.in	Advanced Data Management Technologies	Batch B		
39	A	PUNJABI ANKITA SUNILKUMAR KAVITA	2024.ankita.punjabi@ves.ac.in	Advanced Data Management Technologies	Batch B		
40	A	PUNJABI BHAVESH MOHAN RIYA	2024.bhavesh.punjabi@ves.ac.in	Advanced Data Management Technologies	Batch B		
41	A	PUNJABI RAHUL MANISH BHAVNA	2024.rahul.punjabi@ves.ac.in	Advanced Data Management Technologies	Batch B		
42	A	PUNWANI YASHIKA HARESHLAL ROSHNI	2024.yashika.punwani@ves.ac.in	Advanced Data Management Technologies	Batch B		
43	A	RAKSHE KIRTEESH DATTATRAY CHHAYA	2024.kirteesh.rakshe@ves.ac.in	Advanced Data Management Technologies	Batch B		
44	A	RAMKRISHNANI DEVIKA NARESH SHEETAL	2024.devik	Advanced Data Management Technologies	Batch B		
45	A	SARAIYA JOLIN MANOJKUMAR SONI	2024.jolin.saraiya@ves.ac.in	Advanced Data Management Technologies	Batch B		
46	A	SARKALE MAYURESH PRAVIN YOGITA	2024.mayuresh.sarkale@ves.ac.in	Advanced Data Management Technologies	Batch B		
47	A	SASNANI VANSHIKA HEMANT NEHA	2024.vanshika.sasnani@ves.ac.in	Advanced Data Management Technologies	Batch C		Charusheela Nehete
48	A	SETYA SAHIL KISHIN HEMA	2024.sahil.setya@ves.ac.in	Advanced Data Management Technologies	Batch C		
49	A	SHUKLA PIYUSH SANJAY MAYA	2024.piyush.shukla@ves.ac.in	Advanced Data Management Technologies	Batch C		
50	A	SINDRA VIKRAM KANARAM SUKIYEDEVI	2024.vikram.sindra@ves.ac.in	Advanced Data Management Technologies	Batch C		
51	A	SINGH ABHINAV RAJESH SUNITA	2024.abhinav.singh@ves.ac.in	Advanced Data Management Technologies	Batch C		
52	A	SINGH ADARSH SHIVANAND RUBY	2024.adarsh.singh@ves.ac.in	Advanced Data Management Technologies	Batch C		
53	A	SINGH VIDUSHI JASWANT NEEMA	2024.vidushi.singh@ves.ac.in	Advanced Data Management Technologies	Batch C		
54	A	TALREJA JAIPRAKASH RAJESH BHAVISHA	2024.jaiprakash.talreja@ves.ac.in	Advanced Data Management Technologies	Batch C		
55	A	TALREJA SUHAN MANISH RASHI	2024.suhan.talreja@ves.ac.in	Advanced Data Management Technologies	Batch C		
56	A	TANWAR ARCHIET VISWAJIT UMA	2024.archiet.tanwar@ves.ac.in	Advanced Data Management Technologies	Batch C		
57	A	TARACHANDANI KONIKA SANJAY KARINA	2024.konika.tarachandani@ves.ac.in	Advanced Data Management Technologies	Batch C		
58	A	TILWANI MOHIT SUDESHKUMAR KANCHAN	2024.mohit.tilwani@ves.ac.in	Advanced Data Management Technologies	Batch C		
59	A	WAGHMODE ATHARVA RAMDAS ANITA	2024.atharva.waghmode@ves.ac.in	Advanced Data Management Technologies	Batch C		
60	A	KAWINNA HARSH JAGDISH SANDHYA	2024.harsh.kawinha@ves.ac.in	Advanced Data Management Technologies	Batch C		
61	A	MOTWANI PIYUSH VINOD HARSHA		Advanced Data Management Technologies	Batch C		
1	B	AHUJA MANAV NAVIN JAYA	2024.manav.ahuja@ves.ac.in	Advanced Data Management Technologies	Batch C		
2	B	AMARNANI KASHISH NARESH DIVYA	2024.kashish.amarnani@ves.ac.in	Advanced Data Management Technologies	Batch C		
3	B	ARORA JAPLEEN KAUR PARVINDER SINGH	2024.japleen.arora@ves.ac.in	Advanced Data Management Technologies	Batch C		
4	B	AWASTHI SHRUTI RAJEEV SHRADDHA	2024.shruti.awasthi@ves.ac.in	Advanced Data Management Technologies	Batch C		
5	B	BHANGALE UNMESH NIRANJAN KAVITA	2024.unmesh.bhangale@ves.ac.in	Advanced Data Management Technologies	Batch C		
6	B	CHHATLANI SIA GHANSHYAM AANCHAL	2024.sia.chhatlani@ves.ac.in	Advanced Data Management Technologies	Batch C		
7	B	DEVADIGA KIRTAN SURESH NAYANA	2024.kirtan.devadiga@ves.ac.in	Advanced Data Management Technologies	Batch C		
8	B	DUBEY ANUSHKA SURENDRA POONAM	2024.anushka.dubey@ves.ac.in	Advanced Data Management Technologies	Batch C		
9	B	FATNANI BHOOMIT RAJESH SAKSHI	2024.bhoomit.fatnani@ves.ac.in	Advanced Data Management Technologies	Batch C	Vidya Pujari	
10	B	GALRANI HITIKA MANISH SNEHA	2024.hitika.galrani@ves.ac.in	Advanced Data Management Technologies	Batch A		Ritwik
11	B	GAVALI KRISHNA BAPU RANJANA	2024.krishna.gavali@ves.ac.in	Advanced Data Management Technologies	Batch A		
12	B	GHODVINDE ADHYATMIKA RAMDAS RASIKA	d2025.adhyatmika.ghodvinde@ves.ac.in	Advanced Data Management Technologies	Batch A		
13	B	GORE ABHISHEK ARUN ARCHANA	2024.abhishek.gore@ves.ac.in	Advanced Data Management Technologies	Batch A		
14	B	GUPTA KRRISH JITENDRA ANGIRA	2024.krrish.gupta@ves.ac.in	Advanced Data Management Technologies	Batch A		
15	B	GUPTA RUSHABH VINOD MEENA	2024.rushabh.gupta@ves.ac.in	Advanced Data Management Technologies	Batch A		
16	B	HASWANI DHRUV RAVI SAKSHI	2024.dhruv.haswani@ves.ac.in	Advanced Data Management Technologies	Batch A		
17	B	HOTWANI SAAKHI VINOD HEENA	2024.saakhi.hotwani@ves.ac.in	Advanced Data Management Technologies	Batch A		
18	B	KADAM ARYAN VINAY SWAPNA	2024.aryan.kadam@ves.ac.in	Advanced Data Management Technologies	Batch A		
19	B	KALE ARNAV MANOJ SMITA	d2025.arnav.kale@ves.ac.in	Advanced Data Management Technologies	Batch A		
20	B	KHISMATRAO PARTH RAHUL SWARDA	2024.parth.khismatrao@ves.ac.in	Advanced Data Management Technologies	Batch A		
21	B	LACHHWANI SHUBHAM MAHESH BHOOMI	2024.shubham.lachhwani@ves.ac.in	Advanced Data Management Technologies	Batch A		
22	B	LALWANI DISHA RAKESH BHAVIKA	2024.disha.lalwani@ves.ac.in	Advanced Data Management Technologies	Batch A		
23	B	MADHYAN PARI RAJESH BHAWANA	2024.pari.madhyan@ves.ac.in	Advanced Data Management Technologies	Batch A		
24	B	MAHAJAN PRASAD NARENDRA NILIMA	2024.prasad.mahajan@ves.ac.in	Advanced Data Management Technologies	Batch A		
25	B	MAINANI LOKESH DHANRAJ KOMAL	2024.lokesh.mainani@ves.ac.in	Advanced Data Management Technologies	Batch A		
26	B	MANKAR SHRAVANI JITENDRA LEENA	2024.shravani.mankar@ves.ac.in	Advanced Data Management Technologies	Batch A		
27	B	MASCARENHAS AADIT RAJESH RASHMI	2024.aadit.mascarenhas@ves.ac.in	Advanced Data Management Technologies	Batch A		
28	B	MHATRE NUPUR LALIT SHRUTI	2024.nupur.mhatre@ves.ac.in	Advanced Data Management Technologies	Batch A		
29	B	MOHITE PARTH PARITOSH ARCHANA	2024.parth.mohite@ves.ac.in	Advanced Data Management Technologies	Batch A		
30	B	MOTWANI VINAY SUNDER ARTI	2024.vinay.motwani@ves.ac.in	Advanced Data Management Technologies	Batch A		
31	B	NAIK GOURISH GANPATI VANITA	2024.gourish.naik@ves.ac.in	Advanced Data Management Technologies	Batch A		
32	B	PAHUJA VANSH GOPAL ANISHA	d2025.vansh.pahuja@ves.ac.in	Advanced Data Management Technologies	Batch A		
33	B	PAREKAR MANAS SHAILESH SHILPA	d2025.manas.parekar@ves.ac.in	Advanced Data Management Technologies	Batch A		
34	B	PATIL ANIRUDDHA SURESH ROHINI	2024.aniruddha.patil@ves.ac.in	Advanced Data Management Technologies	Batch B		
35	B	PATIL KAUSTUBH UMESH MANISHA	2024.kaustubh.patil@ves.ac.in	Advanced Data Management Technologies	Batch B		
36	B	PATIL PRADNYESH PRASHANT SHEETAL	2024.pradnyesh.patil@ves.ac.in	Advanced Data Management Technologies	Batch B		Ritwik
37	B	PATIL TANAY SAMIR SAMIRA	2024.tanay.patil@ves.ac.in	Advanced Data Management Technologies	Batch B		
38	B	PRAKASH SURAJ SANJIV REENA	2024.prakash.suraj@ves.ac.in	Advanced Data Management Technologies	Batch B		
39	B	RAGHANI SHANTANU SUNIL KAJAL	2024.shantanu.raghani@ves.ac.in	Advanced Data Management Technologies	Batch B		
40	B	RAI AASTHA ASHISH MAMTA	2024.aastha.rai@ves.ac.in	Advanced Data Management Technologies	Batch B		
41	B	RAI YASH SUBBAYYA VIJAYALAKSHMI	2024.yash.rai@ves.ac.in	Advanced Data Management Technologies	Batch B		
42	B	RAJPAL PRIYANKA JAGDISH DEEPA	2024.priyanka.rajpal@ves.ac.in	Advanced Data Management Technologies	Batch B		
43	B	SACHDEV HANSIKA SANDEEP LABHDI	2024.hansika.sachdev@ves.ac.in	Advanced Data Management Technologies	Batch B		
44	B	SAWLANI OM GHANSHYAM RADHA	2024.om.sawlani@ves.ac.in	Advanced Data Management Technologies	Batch B		
45	B	TAWATE TANISHKA AJIT RUPALI	2024.tanishka.tawate@ves.ac.in	Advanced Data Management Technologies	Batch B		
1	C	BINDRANI SIYA KAMLESH MAHEK	2024.siya.bindrani@ves.ac.in	Advanced Data Management Technologies	Batch B		
2	C	CHACHLANI HITEN PRAKASH BHAVIKA	d2025.hiten.chachlani@ves.ac.in	Advanced Data Management Technologies	Batch B		
3	C	CHELANI MAHEK SUNIL KAJAL	2024.mahek.chelani@ves.ac.in	Advanced Data Management Technologies	Batch B		
4	C	DUSEJA KESAR ANIL KARISHMA	2024.kesar.duseja@ves.ac.in	Advanced Data Management Technologies	Batch B		
5	C	EKAWADE ADITI UMESH KRUPA	2024.aditi.ekawade@ves.ac.in	Advanced Data Management Technologies	Batch B		
6	C	GOPLANI YAASHI SHAILENDER ANMOL	2024.yaashi.goplani@ves.ac.in	Advanced Data Management Technologies	Batch B		
7	C	GUNJAL KAUSHAL RAJU SUNANDA	2024.kaushal.gunjal@ves.ac.in	Advanced Data Management Technologies	Batch B		
8	C	HARCHANDANI PALAK ANIL MUSKAN	2024.palak.harchandani@ves.ac.in	Advanced Data Management Technologies	Batch B		
9	C	IYER SABARESH GOVINDAN ABARNA	2024.sabaresh.iyer@ves.ac.in	Advanced Data Management Technologies	Batch B		
10	C	KALEKAR NEEL NIKHIL PRACHI	2024.neel.kalekar@ves.ac.in	Advanced Data Management Technologies	Batch B		
11	C	KARAMCHANDANI HARSHIKA SACHIN	2024.harshika.karamchandani@ves.ac.in	Advanced Data Management Technologies	Batch C		
12	C	KHILNANI VINIT VIJAYKUMAR JIYA	2024.vinit.khilnani@ves.ac.in	Advanced Data Management Technologies	Batch C		
13	C	LABANA SIMRANKAUR JEETENDER SINGH	2024.simrankaur.labana@ves.ac.in	Advanced Data Management Technologies	Batch C		Ritwik
14	C	LALCHANDANI HARSHITA RAJESH BHAVNA	2024.harshita.lalchandani@ves.ac.in	Advanced Data Management Technologies	Batch C		
15	C	LILANI RISHI DINESH HEENA	2024.rishi.lilani@ves.ac.in	Advanced Data Management Technologies	Batch C		
16	C	LUND JANVI BUNTY PRITI	2024.janvi.lund@ves.ac.in	Advanced Data Management Technologies	Batch C		
17	C	MAKHIJA PARAS NARESH JYOTI	2024.paras.makhija@ves.ac.in	Advanced Data Management Technologies	Batch C		
18	C	NATH HITEN SADANAND RADHA	2024.hiten.nath@ves.ac.in	Advanced Data Management Technologies	Batch C		
19	C	PALAV SANIKA SHREERAM RIYA	d2025.sanika.palav@ves.ac.in	Advanced Data Management Technologies	Batch C		
20	C	PATIL SHRAVANI KAMLESH SUSHAMA	2024.shravani.k.patil@ves.ac.in	Advanced Data Management Technologies	Batch C		
21	C	PAYGUDE SHRAVANI NILESH MINAL	2024.shravani.paygude@ves.ac.in	Advanced Data Management Technologies	Batch C		
22	C	PRANAV RAMESH SINDHU	2024.pranav.ramesh@ves.ac.in	Advanced Data Management Technologies	Batch C		
23	C	RAMSAY MAHEK DHARMENDRA ANAMIKA	2024.mahek.ramsay@ves.ac.in	Advanced Data Management Technologies	Batch C		
24	C	RANDHIR NEHA DEEPAK KALPANA	2024.neha.randhir@ves.ac.in	Advanced Data Management Technologies	Batch C		
25	C	RELAN HONEY HEMANT LAXMI	2024.honey.relan@ves.ac.in	Advanced Data Management Technologies	Batch C		
26	C	SANTANI AMAN ANIL HEMA	2024.aman.santani@ves.ac.in	Advanced Data Management Technologies	Batch C		
27	C	SHAMANI GUNJAN NARESH SEJAL	2024.gunjan.shamani@ves.ac.in	Advanced Data Management Technologies	Batch C		
28	C	SINHA ARYAMAN PRAVIN RANI	2024.aryaman.sinha@ves.ac.in	Advanced Data Management Technologies	Batch C		
29	C	TALREJA PREETI DINESHKUMAR SONIYA	d2025.preeti.talreja@ves.ac.in	Advanced Data Management Technologies	Batch C		
30	C	VALWANI VIDHI VINOD HEENA	2024.vidhi.valwani@ves.ac.in	Advanced Data Management Technologies	Batch C		
70	B	VIRWANI PRITHVIRAJ JEEVA GAYATRI 		Advanced Data Management Technologies	Batch C		
71	B	JAGUJA VIREN SUNIL ANISHA		Advanced Data Management Technologies	Batch C		
72	A	KHADKE SUBODH YUVRAJ MINAKSHI 	2023.subodh.khadke@ves.ac.in	Advanced Data Management Technologies	Batch C	Charusheela Mam	Charusheela Mam
69	C	NAGARE ROHIT SAMPAT SUNITA	2022.rohit.nagare@ves.ac.in	Advanced Data Management Technologies	Batch C	Vidya Pujari	Ritwik
70	C	NARAYANI PREM MUKESH BHAVIKA	2023.prem.narayani@ves.ac.in	Advanced Data Management Technologies			
71	C	OCHANI DRISHTI ANIL MANSHA	2023.drishti.ochani@ves.ac.in	Advanced Data Management Technologies			
62	A	AHUJA RITIKA GIRISH VEDIKA	2024.ritika.ahuja@ves.ac.in	Soft Computing	Batch A	Shanta Sondur	Shanta Sondur
63	A	AHUJA RONIT MANISH PINKY	2024.ronit.ahuja@ves.ac.in	Soft Computing	Batch A		
64	A	ALLE SEJAL SHANKAR BHARGAVI	d2025.sejal.alle@ves.ac.in	Soft Computing	Batch A		
65	A	BAJAJ NAINA BALDEV AANCHAL	2024.naina.bajaj@ves.ac.in	Soft Computing	Batch A		
66	A	BUTANI DISHITA SANJAY KANCHHAN		Soft Computing	Batch A		
67	A	KUKREJA PALAK KISHORE MUSKAN	2024.palak.kukreja@ves.ac.in	Soft Computing	Batch A		
68	A	LOHANA NIHAR GULABCHAND NEETA	2024.nihar.lohana@ves.ac.in	Soft Computing	Batch A		
69	A	LULLA SONIYA VIJAYKUMAR PRIYA	2024.soniya.lulla@ves.ac.in	Soft Computing	Batch A		
70	A	MOTWANI ANSH MAHESH RESHMA	2024.ansh.motwani@ves.ac.in	Soft Computing	Batch A		
71	A	NATHANI DEVAANSH DEEPAK PRIYA	2024.devaansh.nathani@ves.ac.in	Soft Computing	Batch A		
31	C	BAJAJ GAYATRI ANIL MUSKAN	d2025.gayatri.bajaj@ves.ac.in	Soft Computing	Batch A		
32	C	BALIGA SRUTI VIVEKANAND LALITA	2024.sruti.baliga@ves.ac.in	Soft Computing	Batch A		
33	C	BAMANE PRAJUSHA RAJESH VIJAYA	d2025.prajusha.bamane@ves.ac.in	Soft Computing	Batch A		
34	C	BARVE SUMIT RAVINDRA JAYASHREE	d2025.sumit.barve@ves.ac.in	Soft Computing	Batch A		
35	C	BHAKTE AMBHRUNI ASHOK PRAGATI	2024.ambhruni.bhakte@ves.ac.in	Soft Computing	Batch A		
36	C	CHANDWANI SUSHMITA VICKY HANISHA	2024.sushmita.chandwani@ves.ac.in	Soft Computing	Batch A		
37	C	CHAUDHARI HARSH DHANANJAY NITA	2024.harsh.chaudhari@ves.ac.in	Soft Computing	Batch A		
38	C	DEMBLA RISHI NAVIN JANHVI	2024.rishi.dembla@ves.ac.in	Soft Computing	Batch A		
39	C	DESHPANDE VAIDEHI GOPAL JAYSHRI	2024.vaidehi.deshpande@ves.ac.in	Soft Computing	Batch A		
40	C	DOIPHODE YASH GAJANAN SHWETA	2024.yash.doiphode@ves.ac.in	Soft Computing	Batch A		
41	C	GOWDA JAIDEEP MANJUNATH VIJAYALAXMI	2024.jaideep.gowda@ves.ac.in	Soft Computing	Batch A		
42	C	HARCHANDANI PRAGATI SUNIL KANAN	2024.pragati.harchandani@ves.ac.in	Soft Computing	Batch A		
43	C	INAMDAR AMEYA AVADHUT GAURI	2024.ameya.inamdar@ves.ac.in	Soft Computing	Batch A		
44	C	JADHAV PUSHKAR SANTOSH YOGITA	2024.pushkar.jadhav@ves.ac.in	Soft Computing	Batch A		
45	C	JADHAV SAMRUDDH SAGAR PALAK	2024.samruddh.jadhav@ves.ac.in	Soft Computing	Batch B		X2
46	C	JAGDALE SIDDHARTH ANANDRAO SUREKHA	2024.siddharth.jagdale@ves.ac.in	Soft Computing	Batch B		
47	C	KAZI MOHD ARKAM ILYAS SHABANA	2024.mohd.kazi@ves.ac.in	Soft Computing	Batch B		
48	C	KHAN ALINA MOHAMMED SALIM RUBINA	2024.alina.khan@ves.ac.in	Soft Computing	Batch B		
49	C	KHANVILKAR GAURANG NILESH SARIKA	2024.gaurang.khanvilkar@ves.ac.in	Soft Computing	Batch B		
50	C	KHEMANI AASHIKA DEEPAK HARSHA	2024.aashika.khemani@ves.ac.in	Soft Computing	Batch B		
51	C	MAKHIJA JAYESH NANDLAL JHANVI	2024.jayesh.makhija@ves.ac.in	Soft Computing	Batch B		
52	C	MONDAL RITTAM TAPAN RIYA	2025.rittam.mondal@vesititit	Soft Computing	Batch B		
53	C	NADAR MADHAVAN KATHIRVEL RAMALAXMI	2024.madhavan.nadar@ves.ac.in	Soft Computing	Batch B		
54	C	NIRMAL SAHIL VIKAS POONAM	2024.sahil.nirmal@ves.ac.in	Soft Computing	Batch B		
55	C	PANDEY HRITIK SANJAY RANJANA	2024.hritik.pandey@ves.ac.in	Soft Computing	Batch B		
56	C	PATHAK SUMIT VIPIN NEERAJ	2024.sumit.pathak@ves.ac.in	Soft Computing	Batch B		
57	C	PATIL SWAGAT NINAD NEHA	d2025.swagat.patil@ves.ac.in	Soft Computing	Batch B		
58	C	SHARMA AKSHAY DEEPAK HIMANSHI	 2023.akshay.sharma@ves.ac.in	Soft Computing	Batch B		
59	C	SHRIVASTAVA AYUSH RITESH KUMAR NITU	2024.ayush.shrivastava@ves.ac.in	Soft Computing	Batch B		
60	C	SHUGANI DIMPLE SHANKARLAL KAJAL	2024.dimple.shugani@ves.ac.in	Soft Computing	Batch B		
61	C	SIRWANI MRINAL PRAKASH NEHA	2024.mrinal.sirwani@ves.ac.in	Soft Computing	Batch B		
62	C	SUHANDA MEET LALIT MALA	2024.meet.suhanda@ves.ac.in	Soft Computing	Batch B		
63	C	TALREJA DIKSHA SANTOSH ANJALI	2024.diksha.talreja@ves.ac.in	Soft Computing	Batch B		
64	C	TARWANI RANJINI KUMAR RISHIKA	2024.ranjini.tarwani@ves.ac.in	Soft Computing	Batch B		
65	C	VALECHA NIHARIKA PRADEEP NISHITA	2024.niharika.valecha@ves.ac.in	Soft Computing	Batch B		
66	C	WADHWA PAVAN VIJAY MAMTA		Soft Computing	Batch B		
67	C	YADAV ADITYA RAJENDRA MADHULIKA	2024.aditya.yadav@ves.ac.in 	Soft Computing	Batch B		
68	C	YADAV KOMAL MANOJ SAVITA	2024.komal.yadav@ves.ac.in	Soft Computing	Batch B		
46	B	ARUJA ARYA HARISH GEETA	2024.arya.aruja@ves.ac.in	Soft Computing	Batch C		Rahul Kumar
47	B	CHURYAI BHAVESH LADHARAM MADHU	2024.bhavesh.churyai@ves.ac.in	Soft Computing	Batch C		
48	B	DUSEJA KRISHNA HARESH MAHEK	2024.krishna.duseja@ves.ac.in	Soft Computing	Batch C		
49	B	GAWAD KSHITIJ VASANT SUJATA	2024.kshitij.gawad@ves.ac.in	Soft Computing	Batch C		
50	B	GHARAT VEDANT VIKAS VIKRANTI	2024.vedant.gharat@ves.ac.in	Soft Computing	Batch C		
51	B	JETHANI MANAV GHANSHYAM ROSHINI	2024.manav.jethani@ves.ac.in	Soft Computing	Batch C		
52	B	KHALSA JASKARAN JASPAL SINGH	2024.jaskaran.khalsa@ves.ac.in	Soft Computing	Batch C		
53	B	KHUBCHANDANI KANCHAN GOVIND KASHISH	d2025.kanchan.khubchandani@ves.ac.in	Soft Computing	Batch C		
54	B	KUMAR RISHABH VINOD LALITA	2024.rishabh.rumar@ves.ac.in	Soft Computing	Batch C		
55	B	LOKHANDE AYUSH MADHUKAR KANCHAN	2024.ayush.lokhande@ves.ac.in	Soft Computing	Batch C		
56	B	LULLA PRIYAM MAHESH DEEPA	2024.priyam.lulla@ves.ac.in	Soft Computing	Batch C		
57	B	MANDHAN RONIT YOGESH MAHEK	2024.ronit.mandhan@ves.ac.in	Soft Computing	Batch C		
58	B	NEBHANI GEETIKA NARAIN SNEHA	2024.geetika.nebhani@ves.ac.in	Soft Computing	Batch C		
59	B	NISHAD DEEPAK RAMNARAYAN RAJKALI	2024.deepak.nishad@ves.ac.in	Soft Computing	Batch C		
60	B	PAWAR SHRUTIKA GANESH LEENA	2024.shrutika.pawar@ves.ac.in	Soft Computing	Batch C		
61	B	RUPLANI HIMANI KAMLESH PREETI	2024.himani.ruplani@ves.ac.in	Soft Computing	Batch C		
62	B	SABHANI HISHITA PARSHOTAM KIRAN	d2025.hishita.sabhani@ves.ac.in	Soft Computing	Batch C		
63	B	SANTANI VARUN VINOD DISHA	2024.varun.santani@ves.ac.in	Soft Computing	Batch C		
64	B	SHARMA JATIN RAJKUMAR SEEMA	2024.jatin.sharma@ves.ac.in	Soft Computing	Batch C		
65	B	TALREJA TANISH SANJAY KARISHMA	2024.tanish.talreja@ves.ac.in	Soft Computing	Batch C		
66	B	VALECHA HEENA NEERAJ DEEPTI	2024.heena.valecha@ves.ac.in	Soft Computing	Batch C		
67	B	VALECHA SAHIL KISHORE RIYA	2024.sahil.valecha@ves.ac.in	Soft Computing	Batch C		
68	B	VALECHA VANSH MANOJ RITU	2024.vansh.valecha@ves.ac.in	Soft Computing	Batch C		
69	B	YADAV AYUSH MUKESH SUNITA	2024.ayush.yadav@ves.ac.in	Soft Computing	Batch C		`;

// Since we are mapping students to their respective Core batch (A/B/C) based on roll number ranges (implicitly)
// The raw data gives us: Roll, Division, Name, Email, Elective, Elective Batch
// The core batch for third year is usually: Rolls 1-25 (Batch A), 26-50 (Batch B), 51-75 (Batch C) roughly.
// We can assign CoreBatch based on standard split (which was what we saw earlier).
function getCoreBatch(rollNo) {
  const r = parseInt(rollNo);
  if (r <= 25) return 'Batch A';
  if (r <= 50) return 'Batch B';
  return 'Batch C';
}

function processStudents() {
  const lines = rawData.trim().split('\n');
  const students = [];

  for (let line of lines) {
    if (!line.trim()) continue;
    // Split by tabs
    const parts = line.split('\t').map(p => p.trim());
    if (parts.length < 6) continue;

    const rollNo = parts[0];
    const div = parts[1];
    const name = parts[2];
    const email = parts[3] || `student${rollNo}${div}@ves.ac.in`;
    const electiveSubject = parts[4] === 'Advanced Data Management Technologies' ? 'ADMT' : 
                            (parts[4] === 'Soft Computing' ? 'Soft Computing' : parts[4]);
    const electiveBatch = parts[5];
    
    // Core Batch is generally 1-25=A, 26-50=B, 51-75=C
    const coreBatch = getCoreBatch(rollNo);
    const divisionStr = `D15${div}`;

    const id = crypto.randomUUID();
    students.push({
      id,
      name,
      rollNo,
      email,
      division: divisionStr,
      coreBatch: coreBatch,
      electiveSubject: electiveSubject,
      electiveBatch: electiveBatch
    });
  }

  return students;
}

const students = processStudents();
console.log(`Parsed ${students.length} students from the Excel dump.`);

db.serialize(() => {
  // Insert faculties
  db.run(`INSERT INTO users (id, role, name, rollNo, email, password, profilePictureUrl, division, coreBatch, electiveSubject, electiveBatch) VALUES 
        ('fac-123', 'faculty', 'John Smith', NULL, 'john.smith@ves.ac.in', 'smith2024', NULL, NULL, NULL, NULL, NULL),
        ('fac-124', 'faculty', 'Christopher Alexander Williams', NULL, 'christopher.alexander.williams@ves.ac.in', 'chrisSecure99', NULL, NULL, NULL, NULL, NULL),
        ('fac-125', 'faculty', 'Maximillian Bartholomew III', NULL, 'maximillian.bartholomew.iii@ves.ac.in', 'maxPass007', NULL, NULL, NULL, NULL, NULL),
        ('fac-126', 'faculty', 'Rajendra Prasad Chattopadhyay Sharma', NULL, 'rajendra.prasad.chattopadhyay.sharma@ves.ac.in', 'rajendra456', NULL, NULL, NULL, NULL, NULL)
  `);

  // Insert students
  const stmt = db.prepare(`INSERT INTO users (id, role, name, rollNo, email, password, profilePictureUrl, division, coreBatch, electiveSubject, electiveBatch) VALUES (?, 'student', ?, ?, ?, 'pass123', NULL, ?, ?, ?, ?)`);
  
  for (const s of students) {
    stmt.run([s.id, s.name, s.rollNo, s.email, s.division, s.coreBatch, s.electiveSubject, s.electiveBatch]);
  }
  stmt.finalize();

  console.log('Database seeded successfully!');
});
