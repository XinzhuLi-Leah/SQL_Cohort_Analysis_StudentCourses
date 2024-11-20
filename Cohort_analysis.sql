-- 请注意啊 date_format 返回的是字符串，TIMESTAMPDIFF 的行为，它需要两个参数都是有效的日期或时间类型（如 DATE、DATETIME）。


with tmp2 as
(select date_format(date_registered, '%Y-%m') as cohort,   -- 这是在计算每个分组的人数。是按照注册月份来分组的。
count(distinct student_id) as count_registered_users         -- 即是看看每个月有多少学生注册
from student_info
group by cohort
),
tmp3 as 
(
select                                                    -- 然后这一部分就需要把学生的活跃表join进来了
		date_format(date_registered, '%Y-%m') as cohort,
		TIMESTAMPDIFF(MONTH, date(date_registered),date(date_engaged)) as month_diff,
        count(distinct si.student_id) as count_active_users
from student_info as si
left join student_engagement as se
on si.student_id=se.student_id
where date_format(se.date_engaged, '%Y-%m') is not null   -- 排除那些注册之后就完全消失的学生
group by cohort,month_diff                                -- 根据组别还有 diff去group by ,比如说我1月注册的， 3 ，4，5，6都活跃了，那么diff是2，3，4，5，都会把我算进去->							
)
select 
tmp3.cohort,
tmp3.month_diff,
tmp3.count_active_users,
tmp3.count_active_users - lag(tmp3.count_active_users,1,0) over(partition by cohort order by month_diff) as change_numbers,
tmp2.count_registered_users,
round((tmp3.count_active_users/tmp2.count_registered_users),2) as retention_rate -- 然后就是计算留存率。就是看看活跃的人数占每个月的注册人数的比率
from tmp3 
left join tmp2
ON tmp2.cohort = tmp3.cohort
order by tmp3.cohort,tmp3.month_diff


