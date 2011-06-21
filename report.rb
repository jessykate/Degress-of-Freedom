#!/usr/bin/ruby

=begin

to import the database on a local machine:
1. download the .sql file
scp username@server.com:path/to/dump.sql .

2. create a new database (use different credentials as needed)
mysqladmin create lernanta_anon -u root

3. import the sql file (use different credentials as needed)
mysql -u root lernanta_anon < lernanta20110615_anonym.sql 

install the necessary ruby dependencies
sudo gem install mysql

update the databases settings at the top of the script to reflect your local
user and database information

run the script:
./report.rb

=end

require 'rubygems'
require 'mysql'

username = "root"
password = ""
database = "lernanta_anon"

# TODO:
# q - if a user leaves a course is that reflected in the following tables?
# issues - most of the counts are not accounting for duplicates/ 
# also participant counts should exclude organizers
# need a query about course state
# clarify that queries about courses include those under development


############### queries  ##################


queries = {
	:users_total, "select count(*) as total_users from users_userprofile",
	:new_users_by_day, "select count(id) as new_users, DATE_FORMAT(created_on, '%Y-%m-%d') as date from users_userprofile group by date",
	:new_courses_by_day, "select count(id) as new_courses, DATE_FORMAT(created_on, '%Y-%m-%d') as date from projects_project group by date",

	# returns num_participants, course_id, course_name
	:participants_per_course, "select count(user_id) as num_participants, project_id, name from projects_participation, projects_project where projects_project.id=project_id group by project_id order by num_participants desc",

	# returns total_following_or_participating, course_id, course_name
	:f_or_p_per_course, "select count(source_id) as follow_or_particip, target_project_id, name from relationships_relationship, projects_project where projects_project.id = target_project_id group by target_project_id order by follow_or_particip desc",

	# returns num_courses, school_id, school_name
	:courses_per_school, "select count(projects_project.id) as num_courses, school_id, schools_school.name from projects_project, schools_school where schools_school.id = school_id group by school_id",

	# not quite right - not accounting for duplicates, 
	#partic_per_school = "select count(user_id) as num_participants, school_id, schools_school.name from projects_participation, projects_project, schools_school where projects_project.id=project_id and projects_project.school_id=schools_school.id group by school_id order by num_participants desc"

	# not quite right - not accounting for duplicates, 
	:partic_per_school, "select sum(partic) as participants_per_school, school_id, name from (select count(user_id) as partic, project_id, school_id, schools_school.name as name from projects_project, projects_participation, schools_school where projects_project.id = project_id and projects_project.school_id=schools_school.id group by project_id order by partic) as subq group by school_id",

	# not quite right - not accounting for duplicates, 
	:f_and_p_per_school, "select sum(f_or_p) as users_per_school, school_id from (select count(source_id) as f_or_p, target_project_id, school_id, name from relationships_relationship, projects_project where projects_project.id = target_project_id group by target_project_id order by f_or_p) as subq group by school_id",

	# get school name but lose nulls (need to use a different kind of join)
	# not quite right - not accounting for duplicates, 
	#:f_and_p_per_school, "select sum(f_or_p) as users_per_school, school_id, name from (select count(source_id) as f_or_p, target_project_id, school_id, schools_school.name from schools_school, relationships_relationship, projects_project where projects_project.id = target_project_id and projects_project.school_id = schools_school.id group by target_project_id order by f_or_p) as subq group by school_id",

	# number of follow relationships between users
	:total_user_follows, "select count(*) as user_follows from relationships_relationship where target_user_id is not null",

	# users not participating in any course
	:users_not_participating, "select count(users_userprofile.user_id) num_not_participating, projects_participation.project_id from projects_participation RIGHT JOIN users_userprofile ON users_userprofile.id = projects_participation.user_id where projects_participation.project_id is NULL",

	# number of distinct users participating in at least one course
	:distinct_users_participating, "select count(distinct user_id) as distinct_users_participating from projects_participation",
}

db = Mysql.real_connect("localhost", username, password, database)

queries.each{|key, q|
	res = db.query(q)
	puts " ================= #{key} =================="
	col_names = []
	res.fetch_fields.each{|f|
		col_names << f.name
	}
	puts col_names.join("\t")
	puts "----------------------------"
	res.each{|row|
		puts row.join("\t")
	}
	puts ""
	puts ""
}

