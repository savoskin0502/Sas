/* Сгенерированный код (ИМПОРТ) */
/* Исходный файл: Official_Foreign_Exchange_Rates_NBRK_on_03_04_2019.xls */
/* Путь к источнику: /home/savoskin05000/sasuser.v94 */
/* Дата генерации кода: 03.04.19, 19:29 */

%web_drop_table(WORK.IMPORT);


FILENAME REFFILE '&homepath/sasuser.v94/Official_Foreign_Exchange_Rates_NBRK_on_03_04_2019.xls';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLS
	OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.IMPORT; RUN;


%web_open_table(WORK.IMPORT);

proc sql;
	create table t as
	Select *
	From work.import
	Where DATE> '2015-12-31';
run;

/* proc print data = t;run; */

/* proc sql; */
/* 	create table s1 as */
/* 	Select * */
/* 	From t */
/* 	Where USD<>'.'; */
/* quit; */

/* proc print data=t;run; */

DATA DAY1;
    SET t;
    ID+1;
RUN;




DATA DAY2;

    SET DAY1 t;

    RETAIN _ID;

    IF ID ~= . THEN _ID = ID;

    ELSE DO;
        _ID+1;
    END;
    DROP ID;

    RENAME _ID = ID;

RUN;


proc sql;
	create table day3 as
	Select *
	From day2
	Where ID < 1190;
run;


proc arima data=day3;
   identify var=USD scan;
run;

ods graphics;
PROC VARMAX data=day3 plot=forecasts(all); 
	id id interval=day;
	model USD/method=ml minic=(type=sbc p=2 q=0) dif=(USD(360)) trend=linear;
	output out=out lead=270;
run;
ods graphics off;




