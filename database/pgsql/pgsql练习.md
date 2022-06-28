# pgsql练习

这里主要给题和答案。  
结果是跑出来了，但不保证最优。（最优是一个非常复杂的问题，我能力有限只能处理一点简单的问题。）  
sql直接写md里了推荐使用IDEA阅读、练习。（支持markdown渲染，从markdown运行Sql等）  
网页端推荐直接简悦转码阅读。（github默认不提供markdown中的postgresql代码块高亮）

## 练习1 - 网传经典sql50道

声明：本节练习主要来源是之前在网上流传的50道SQL练习题，大小问加起来50道左右。[感谢bladeXue](https://github.com/bladeXue/sql50)  
很久之前看到过，这次在github上看到忍不住使用pgsql重做一遍。
答案可以参考上文链接。

这里使用pgsql作为方言给出解法。  
注意使用pgsql默认设置， 关键字、表名、字段名全部不区分大小写。  
这里有时候为了展示思考过程，直接使用 `with` 语法提取子查询。  
正常写直接将子查询带入即可，没必要学我。

### DDL

建表语句

```postgresql
create database "sql50";
-- 切换数据库
\c "sql50";
drop table if exists student;
create table student
(
    id   VARCHAR(64)  not null primary key,
    name VARCHAR(90)  not null,
    age  TIMESTAMP    not null,
    sex  VARCHAR(120) not null
);
-- pgsql不支持在行后直接写注释，我们拿出来写
comment on table student is '学生表';
-- 如果使用 "" 可以指定表名、字段大小写等
comment on column "student"."id" is '学生主键';
comment on column student.name is '学生姓名';
comment on column student.age is '学生年龄';
comment on column student.sex is '学生性别;男、女';

drop table if exists teacher;
create table teacher
(
    id   VARCHAR(64) not null,
    name VARCHAR(90) not null,
    -- 主键可以有两种写法，参照student, teacher
    primary key (id)
);
comment on table teacher is '教师表';
comment on column teacher.id is '教师主键';
comment on column teacher.name is '教师姓名';

drop table if exists course;
create table course
(
    id   VARCHAR(64) not null,
    name VARCHAR(90) not null,
    t_id VARCHAR(64) not null,
    primary key (id)
);
comment on table course is '科目表';
comment on column course.id is '科目主键';
comment on column course.name is '科目名';
comment on column course.t_id is '授课教师主键';

drop table if exists student_course_score;
create table student_course_score
(
    s_id  VARCHAR(64) null,
    c_id  VARCHAR(64) null,
    score decimal(24, 2)
);
comment on table student_course_score is '成绩表';
comment on column student_course_score.s_id is '学生主键';
comment on column student_course_score.c_id is '科目主键';
comment on column student_course_score.score is '成绩;聚合结果保留2位小数';
```

初始化数据

```postgresql
insert into student
values
    ('01', '赵雷', '1990-01-01', '男'),
    ('02', '钱电', '1990-12-21', '男'),
    ('03', '孙风', '1990-12-20', '男'),
    ('04', '李云', '1990-12-06', '男'),
    ('05', '周梅', '1991-12-01', '女'),
    ('06', '吴兰', '1992-01-01', '女'),
    ('07', '郑竹', '1989-01-01', '女'),
    ('09', '张三', '2017-12-20', '女'),
    ('10', '李四', '2017-12-25', '女'),
    ('11', '李四', '2012-06-06', '女'),
    ('12', '赵六', '2013-06-13', '女'),
    ('13', '孙七', '2014-06-01', '女');

insert into teacher
values
    ('01', '张三'),
    ('02', '李四'),
    ('03', '王五');

insert into course
values
    ('01', '语文', '02'),
    ('02', '数学', '01'),
    ('03', '英语', '03');

insert into student_course_score
values
    ('01', '01', 80),
    ('01', '02', 90),
    ('01', '03', 99),
    ('02', '01', 70),
    ('02', '02', 60),
    ('02', '03', 80),
    ('03', '01', 80),
    ('03', '02', 80),
    ('03', '03', 80),
    ('04', '01', 50),
    ('04', '02', 30),
    ('04', '03', 20),
    ('05', '01', 76),
    ('05', '02', 87),
    ('06', '01', 31),
    ('06', '03', 34),
    ('07', '02', 89),
    ('07', '03', 98);
```

### 问题

1. 查询" 01 "课程比" 02 "课程成绩高的学生的信息及课程分数
   解：

```postgresql
-- 分解查询
-- 获取学生01课程成绩
with c_01 as (
    select scs.s_id,
           scs.score as score
    from student_course_score scs
    where c_id = '01')
-- 获取学生01课程成绩
   , c_02 as (
    select scs.s_id,
           scs.score as score
    from student_course_score scs
    where c_id = '02')
select s.*,
       c_01.score as "01课程成绩",
       c_02.score as "02课程成绩"
from c_01
left join c_02 on c_01.s_id = c_02.s_id
left join student s on c_01.s_id = s.id
where c_01.score > c_02.score;
```

结果：

| id  | name | age                        | sex | 01课程成绩 | 02课程成绩 |
|:----|:-----|:---------------------------|:----|:-------|:-------|
| 02  | 钱电   | 1990-12-21 00:00:00.000000 | 男   | 70.00  | 60.00  |
| 04  | 李云   | 1990-12-06 00:00:00.000000 | 男   | 50.00  | 30.00  |

1.1 查询同时存在" 01 "课程和" 02 "课程的情况
解：

```postgresql
with c_01 as (
    select s_id, scs.score
    from student_course_score scs
    where scs.c_id = '01')
   , c_02 as (
        select s_id, scs.score
        from student_course_score scs
        where scs.c_id = '02')
select s.*, c_01.score as "01课程成绩", c_02.score as "02课程成绩"
from c_01
inner join c_02 on c_01.s_id = c_02.s_id
left join student s on c_01.s_id = s.id;
```

结果：

| id  | name | age                        | sex | 01课程成绩 | 02课程成绩 |
|:----|:-----|:---------------------------|:----|:-------|:-------|
| 01  | 赵雷   | 1990-01-01 00:00:00.000000 | 男   | 80.00  | 90.00  |
| 02  | 钱电   | 1990-12-21 00:00:00.000000 | 男   | 70.00  | 60.00  |
| 03  | 孙风   | 1990-12-20 00:00:00.000000 | 男   | 80.00  | 80.00  |
| 04  | 李云   | 1990-12-06 00:00:00.000000 | 男   | 50.00  | 30.00  |
| 05  | 周梅   | 1991-12-01 00:00:00.000000 | 女   | 76.00  | 87.00  |

1.2 查询存在" 01 "课程但可能不存在" 02 "课程的情况(不存在时显示为 null )
解：

```postgresql
with c_01 as (
    select scs.s_id, scs.score
    from student_course_score scs
    where scs.c_id = '01'),
     c_02 as (
         select scs.s_id, scs.score
         from student_course_score scs
         where scs.c_id = '02')
select s.*, c_01.score as "01课程成绩", c_02.score as "02课程成绩"
from c_01 left join c_02 on c_01.s_id = c_02.s_id
left join student s on c_01.s_id = s.id;
```

结果：

| id  | name | age                        | sex | 01课程成绩 | 02课程成绩 |
|:----|:-----|:---------------------------|:----|:-------|:-------|
| 01  | 赵雷   | 1990-01-01 00:00:00.000000 | 男   | 80.00  | 90.00  |
| 02  | 钱电   | 1990-12-21 00:00:00.000000 | 男   | 70.00  | 60.00  |
| 03  | 孙风   | 1990-12-20 00:00:00.000000 | 男   | 80.00  | 80.00  |
| 04  | 李云   | 1990-12-06 00:00:00.000000 | 男   | 50.00  | 30.00  |
| 05  | 周梅   | 1991-12-01 00:00:00.000000 | 女   | 76.00  | 87.00  |
| 06  | 吴兰   | 1992-01-01 00:00:00.000000 | 女   | 31.00  | NULL   |

1.3 查询不存在" 01 "课程但存在" 02 "课程的情况

解：

```postgresql
select s.*, scs.score as "02课程成绩"
from student_course_score scs
left join student s on scs.s_id = s.id
where scs.c_id = '02'
  and scs.s_id not in (
    select distinct scs.s_id
    from student_course_score scs
    where scs.c_id = '01');
```

结果：

| id  | name | age                        | sex | 02课程成绩 |
|:----|:-----|:---------------------------|:----|:-------|
| 07  | 郑竹   | 1989-01-01 00:00:00.000000 | 女   | 89.00  |

2. 查询平均成绩大于等于 60 分的同学的学生编号和学生姓名和平均成绩

解：

```postgresql
with scs_group_by_sid as (
    select scs.s_id, cast(avg(scs.score) as decimal(5, 2)) as avg_score
    from student_course_score scs
    group by scs.s_id
    having avg(scs.score) >= 60)
select s.id as "学生编号", s.name as "学生姓名", scs_group_by_sid.avg_score as "平均成绩"
from scs_group_by_sid inner join student s on scs_group_by_sid.s_id = s.id;
```

结果：

| 学生编号 | 学生姓名 | 平均成绩  |
|:-----|:-----|:------|
| 01   | 赵雷   | 89.67 |
| 02   | 钱电   | 70.00 |
| 03   | 孙风   | 80.00 |
| 05   | 周梅   | 81.50 |
| 07   | 郑竹   | 93.50 |

3. 查询在 SC 表存在成绩的学生信息

解：

```postgresql
select s.*
from student s
where s.id in (
    -- 查单列当数组用
    select distinct scs.s_id
    from student_course_score scs
    where scs.score notnull)
order by s.id;
```

结果：

| id  | name | age                        | sex |
|:----|:-----|:---------------------------|:----|
| 01  | 赵雷   | 1990-01-01 00:00:00.000000 | 男   |
| 02  | 钱电   | 1990-12-21 00:00:00.000000 | 男   |
| 03  | 孙风   | 1990-12-20 00:00:00.000000 | 男   |
| 04  | 李云   | 1990-12-06 00:00:00.000000 | 男   |
| 05  | 周梅   | 1991-12-01 00:00:00.000000 | 女   |
| 06  | 吴兰   | 1992-01-01 00:00:00.000000 | 女   |
| 07  | 郑竹   | 1989-01-01 00:00:00.000000 | 女   |

4. 查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩(没成绩的显示为 null )

解：

```postgresql
select s.id                          as "学生编号",
       s.name                        as "学生姓名",
       coalesce(scs.count_course, 0) as "选课总数",
       scs.sum_score                 as "总成绩"
from (
    select scs.s_id,
           count(*)       as count_course,
           sum(scs.score) as sum_score
    from student_course_score scs
    group by scs.s_id) scs
full join student s on scs.s_id = s.id
order by s.id;
```

结果：

| 学生编号 | 学生姓名 | 选课总数 | 总成绩  |
|:-----|:-----|:-----|:-----|
| 01   | 赵雷   | 3    | 269  |
| 02   | 钱电   | 3    | 210  |
| 03   | 孙风   | 3    | 240  |
| 04   | 李云   | 3    | 100  |
| 05   | 周梅   | 2    | 163  |
| 06   | 吴兰   | 2    | 65   |
| 07   | 郑竹   | 2    | 187  |
| 09   | 张三   | 0    | NULL |
| 10   | 李四   | 0    | NULL |
| 11   | 李四   | 0    | NULL |
| 12   | 赵六   | 0    | NULL |
| 13   | 孙七   | 0    | NULL |

4.1 查有成绩的学生信息

解：

```postgresql
select s.*
from student s
where s.id in (
    select distinct s_id
    from student_course_score scs
    where scs.score notnull)
order by s.id; 
```

结果：

| id  | name | age                        | sex |
|:----|:-----|:---------------------------|:----|
| 01  | 赵雷   | 1990-01-01 00:00:00.000000 | 男   |
| 02  | 钱电   | 1990-12-21 00:00:00.000000 | 男   |
| 03  | 孙风   | 1990-12-20 00:00:00.000000 | 男   |
| 04  | 李云   | 1990-12-06 00:00:00.000000 | 男   |
| 05  | 周梅   | 1991-12-01 00:00:00.000000 | 女   |
| 06  | 吴兰   | 1992-01-01 00:00:00.000000 | 女   |
| 07  | 郑竹   | 1989-01-01 00:00:00.000000 | 女   |

5. 查询「李」姓老师的数量

解：

```postgresql
select count(*) as "李姓老师数量"
from teacher t
where t.name like '李%';
```

结果：

| 李姓老师数量 |
|:-------|
| 1      |

6. 查询学过「张三」老师授课的同学的信息

解：

```postgresql
-- 注意，这里并没有说只有一个张三老师
-- 1. 嵌套范围查
explain analyse
select s.*
from student_course_score scs
inner join student s on scs.s_id = s.id
where scs.c_id in (
    select c.id
    from course c
    where c.t_id in (
        select t.id
        from teacher t
        where t.name = '张三'));

-- 2. 全部表连接
select s.*
from teacher t inner join course c on t.id = c.t_id
inner join student_course_score scs on c.id = scs.c_id
inner join student s on scs.s_id = s.id
where t.name = '张三';
```

嵌套范围查执行计划：

```queryplan
Nested Loop  (cost=24.70..37.84 rows=1 width=610) (actual time=0.042..0.049 rows=6 loops=1)
  ->  Hash Semi Join  (cost=24.55..37.47 rows=1 width=146) (actual time=0.028..0.030 rows=6 loops=1)
        Hash Cond: ((scs.c_id)::text = (c.id)::text)
        ->  Seq Scan on student_course_score scs  (cost=0.00..12.30 rows=230 width=292) (actual time=0.009..0.010 rows=18 loops=1)
        ->  Hash  (cost=24.54..24.54 rows=1 width=146) (actual time=0.015..0.015 rows=1 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 9kB
              ->  Hash Join  (cost=12.64..24.54 rows=1 width=146) (actual time=0.014..0.014 rows=1 loops=1)
                    Hash Cond: ((c.t_id)::text = (t.id)::text)
                    ->  Seq Scan on course c  (cost=0.00..11.50 rows=150 width=292) (actual time=0.002..0.002 rows=3 loops=1)
                    ->  Hash  (cost=12.62..12.62 rows=1 width=146) (actual time=0.008..0.008 rows=1 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 9kB
                          ->  Seq Scan on teacher t  (cost=0.00..12.62 rows=1 width=146) (actual time=0.005..0.006 rows=1 loops=1)
                                Filter: ((name)::text = '张三'::text)
                                Rows Removed by Filter: 2
  ->  Index Scan using student_pkey on student s  (cost=0.14..0.37 rows=1 width=610) (actual time=0.003..0.003 rows=1 loops=6)
        Index Cond: ((id)::text = (scs.s_id)::text)
Planning Time: 0.157 ms
Execution Time: 0.075 ms
```

全部表连接执行计划：

```queryplan
Nested Loop  (cost=24.70..38.10 rows=1 width=610) (actual time=0.056..0.064 rows=6 loops=1)
  ->  Hash Join  (cost=24.55..37.73 rows=1 width=146) (actual time=0.038..0.041 rows=6 loops=1)
        Hash Cond: ((scs.c_id)::text = (c.id)::text)
        ->  Seq Scan on student_course_score scs  (cost=0.00..12.30 rows=230 width=292) (actual time=0.012..0.013 rows=18 loops=1)
        ->  Hash  (cost=24.54..24.54 rows=1 width=146) (actual time=0.020..0.020 rows=1 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 9kB
              ->  Hash Join  (cost=12.64..24.54 rows=1 width=146) (actual time=0.019..0.019 rows=1 loops=1)
                    Hash Cond: ((c.t_id)::text = (t.id)::text)
                    ->  Seq Scan on course c  (cost=0.00..11.50 rows=150 width=292) (actual time=0.003..0.003 rows=3 loops=1)
                    ->  Hash  (cost=12.62..12.62 rows=1 width=146) (actual time=0.011..0.011 rows=1 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 9kB
                          ->  Seq Scan on teacher t  (cost=0.00..12.62 rows=1 width=146) (actual time=0.007..0.008 rows=1 loops=1)
                                Filter: ((name)::text = '张三'::text)
                                Rows Removed by Filter: 2
  ->  Index Scan using student_pkey on student s  (cost=0.14..0.37 rows=1 width=610) (actual time=0.003..0.003 rows=1 loops=6)
        Index Cond: ((id)::text = (scs.s_id)::text)
Planning Time: 0.204 ms
Execution Time: 0.098 ms
```

结果：

| id  | name | age                        | sex |
|:----|:-----|:---------------------------|:----|
| 01  | 赵雷   | 1990-01-01 00:00:00.000000 | 男   |
| 02  | 钱电   | 1990-12-21 00:00:00.000000 | 男   |
| 03  | 孙风   | 1990-12-20 00:00:00.000000 | 男   |
| 04  | 李云   | 1990-12-06 00:00:00.000000 | 男   |
| 05  | 周梅   | 1991-12-01 00:00:00.000000 | 女   |
| 07  | 郑竹   | 1989-01-01 00:00:00.000000 | 女   |

7. 查询没有学全所有课程的同学的信息

8. 查询至少有一门课与学号为" 01 "的同学所学相同的同学的信息

9. 查询和" 01 "号的同学学习的课程完全相同的其他同学的信息

10. 查询没学过"张三"老师讲授的任一门课程的学生姓名

11. 查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩

12. 检索" 01 "课程分数小于 60，按分数降序排列的学生信息

13. 按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩

14. 查询各科成绩最高分、最低分和平均分：

    以如下形式显示：课程 ID，课程 name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率
    及格为>=60，中等为：70-80，优良为：80-90，优秀为：>=90
    要求输出课程号和选修人数，查询结果按人数降序排列，若人数相同，按课程号升序排列

15. 按各科成绩进行排序，并显示排名， Score 重复时保留名次空缺

15.1 按各科成绩进行排序，并显示排名， Score 重复时合并名次

16. 查询学生的总成绩，并进行排名，总分重复时保留名次空缺

16.1 查询学生的总成绩，并进行排名，总分重复时不保留名次空缺

17. 统计各科成绩各分数段人数：课程编号，课程名称，[100-85]，[85-70]，[70-60]，[60-0] 及所占百分比

18. 查询各科成绩前三名的记录

19. 查询每门课程被选修的学生数

20. 查询出只选修两门课程的学生学号和姓名

21. 查询男生、女生人数

22. 查询名字中含有「风」字的学生信息

23. 查询同名同性学生名单，并统计同名人数

24. 查询 1990 年出生的学生名单

25. 查询每门课程的平均成绩，结果按平均成绩降序排列，平均成绩相同时，按课程编号升序排列

26. 查询平均成绩大于等于 85 的所有学生的学号、姓名和平均成绩

27. 查询课程名称为「数学」，且分数低于 60 的学生姓名和分数

28. 查询所有学生的课程及分数情况（存在学生没成绩，没选课的情况）

29. 查询任何一门课程成绩在 70 分以上的姓名、课程名称和分数

30. 查询不及格的课程

31. 查询课程编号为 01 且课程成绩在 80 分以上的学生的学号和姓名

32. 求每门课程的学生人数

33. 成绩不重复，查询选修「张三」老师所授课程的学生中，成绩最高的学生信息及其成绩

34. 成绩有重复的情况下，查询选修「张三」老师所授课程的学生中，成绩最高的学生信息及其成绩

35. 查询不同课程成绩相同的学生的学生编号、课程编号、学生成绩

36. 查询每门功成绩最好的前两名

37. 统计每门课程的学生选修人数（超过 5 人的课程才统计）。

38. 检索至少选修两门课程的学生学号

39. 查询选修了全部课程的学生信息

40. 查询各学生的年龄，只按年份来算

41. 按照出生日期来算，当前月日 < 出生年月的月日则，年龄减一

42. 查询本周过生日的学生

43. 查询下周过生日的学生

44. 查询本月过生日的学生

45. 查询下月过生日的学生
