# pgsql学习笔记

## 一、 基础操作

```postgresql
-- 1. 创建数据库
create database test;
-- 2. 列举数据库。 mysql -> show databases;
\l;
-- 3. 切换到刚创建的数据库。 mysql -> use test;
\c test;
-- 4. 列举表。 mysql -> show tables;
\dt;
-- 5. 查看表结构
\d test_table;
-- 6. 查看索引

```
## 二、 DDL

### 创建表

tips: 一个小细节， 在mysql中允许使用如下写法，但是反引号并不是一个标准语法。所以在pgsql中并不支持。

```mysql
create table `test`(
    id varchar(64) primary key
)
```

在pgsql中，使用双引号。

```postgresql
create table "test" (
    id varchar(64) primary key 
)
```

### 索引

注意和mysql不同，pgsql的索引并不是表级别的，而是整个命名空间的。

所以再创建 pgsql 的索引时，一定要使用 表名_索引类型_索引字段 的格式，防止重名索引。  

## 三、 查询

### 1. `cte`表达式

通用表表达式（Common Table Express， `CTE`）  

使用这种方式将大大替身查询的可读性。

使用前必须先定义。  

```postgresql
-- 想想看，如果这里的etc语句是一个非常复杂的子句，那将极大的降低理解的难度
with etc_name as (
    select 1
    )
    select 2, etc_name.*;
```

然而 `cte` 表达式更厉害的地方在于，可以配合 `recursive` 关键字进行递归使用。  


## 四、 函数

## 五、 PL/Sql
