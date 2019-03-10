# Case-study оптимизации

## Актуальная проблема
В нашем проекте возникла серьёзная проблема.

Необходимо было обработать файл с данными, чуть больше ста мегабайт.

У нас уже была программа на `ruby`, которая умела делать нужную обработку.

Она успешно работала на файлах размером пару мегабайт, но для большого файла она работала слишком долго, и не было понятно, закончит ли она вообще работу за какое-то разумное время.

Я решил исправить эту проблему, оптимизировав эту программу.

## Формирование метрики
Для того, чтобы понимать, дают ли мои изменения положительный эффект на быстродействие программы я придумал использовать такую метрику:

Среднее время выполнения и кол-во аллоцируемой памяти каждых 1000 строк для периода от 10 до 15 тыс. строк.

## Гарантия корректности работы оптимизированной программы
Программа поставлялась с тестом. Выполнение этого теста позволяет не допустить изменения логики программы при оптимизации.

## Feedback-Loop
Для того, чтобы иметь возможность быстро проверять гипотезы я выстроил эффективный `feedback-loop`, который позволил мне получать обратную связь по эффективности сделанных изменений за одну минуту.

Вот как я построил `feedback_loop`:

Внесение изменений в код - Прогон тестов - Проверка улучшения метрик - Коммит изменений

## Вникаем в детали системы, чтобы найти 20% точек роста
Для того, чтобы найти "точки роста" для оптимизации я воспользовался инструментами:

* `GC.stat`
* `MemoryProfiler`
* `ps`
* `ObjectSpace.count_objects`
* `StackProf`
* `RubyProf`

Вот какие проблемы удалось найти и решить

### Ваша находка №1
MemoryProfiler

Аллоцируется 400 Mb объектов класса Array и 16 Mb класса String.
Более всего памяти для класса Array выделяется в строках 53, 54, 100, 102.
Более всего памяти для класса String выделяется в строках 39,46, 52, 139, 142.
Аллоцируются одинаковые строки `" ", "session", ",", "user"`

### Ваша находка №2
StackProf

Object mode

207 000 callees of `file_lines.each`
90 000 callees of `split`

Object#collect_stats_from_users
250 000 callees of `users_objects.each`
190 000 callees of `report['usersStats'][user_key] = report['usersStats'][user_key].merge(block.call(user))`

Wall mode
```
 5822   (93.1%)                    |    98  |   users.each do |user|
                                   |    99  |     attributes = user
 11584  (185.2%) /  5792  (92.6%)  |   100  |     user_sessions = sessions.select { |session| session['user_id'] == user['id'] }
 ```



### Ваша находка №3
RubyProf

Allocations mode
```
 %self      total      self      wait     child     calls  name
 27.38  146929.000 146929.000    0.000    0.000     20001  String#split
 24.28  489625.000 130272.000    0.000 359353.000   10010  *Array#each
 14.20  93120.000  76192.000     0.000 16928.000    8464   <Class::Date>#parse
 ```

Wall mode
```
 %self      total      self      wait     child     calls  name
 91.03      7.694     7.694     0.000     0.000     1536   Array#select
  2.52      8.392     0.213     0.000     8.179     10010  *Array#each
```


## Результаты
В результате проделанной оптимизации наконец удалось обработать файл с данными.
Удалось улучшить метрику системы

### Step 1
Was
```
10000 lines performed in 5.98 s. + 74MB
11000 lines performed in 7.97 s. + 52MB
12000 lines performed in 9.24 s. + 63MB
13000 lines performed in 11.27 s. + -12MB
14000 lines performed in 14.17 s. + 12MB
15000 lines performed in 16.11 s. + 12MB
Average period for each 1000 lines: 2.026s.
Average memory allocation for each 1000 lines: 33.5MB
```

Became
```
10000 lines performed in 0.25 s. + 14MB
11000 lines performed in 0.34 s. + 1MB
12000 lines performed in 0.4 s. + 1MB
13000 lines performed in 0.41 s. + 5MB
14000 lines performed in 0.46 s. + 2MB
15000 lines performed in 0.48 s. + 1MB
Average period for each 1000 lines: 0.046s.
Average memory allocation for each 1000 lines: 4.0MB
```

### Step 2
Was
```
50000 lines performed in 1.26 s. + 68MB
51000 lines performed in 1.45 s. + 6MB
52000 lines performed in 1.52 s. + 1MB
53000 lines performed in 1.58 s. + 0MB
54000 lines performed in 1.85 s. + -2MB
55000 lines performed in 1.58 s. + 64MB
Average period for each 1000 lines: 0.06400000000000002s.
Average memory allocation for each 1000 lines: 22.83MB
```

Became
```
50000 lines performed in 1.09 s. + 66MB
51000 lines performed in 1.28 s. + 6MB
52000 lines performed in 1.37 s. + 2MB
53000 lines performed in 1.4 s. + 1MB
54000 lines performed in 1.52 s. + 0MB
55000 lines performed in 1.54 s. + 0MB
Average period for each 1000 lines: 0.09s.
Average memory allocation for each 1000 lines: 12.5MB
```

*Какими ещё результами можете поделиться*

## Защита от регресса производительности
Для защиты от потери достигнутого прогресса при дальнейших изменениях программы сделано *то, что вы для этого сделали*
