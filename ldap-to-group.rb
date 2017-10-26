# This puts the computers in your JSS into static groups based on an arbitrarily
# decided on ldap attribute. In this case, it's ucscPersonPubAffiliation which
# can be either Faculty, Staff, Undergraduate or Graduate. In order to change this
# to fit your environment, you'll want to modify check_person_type's grep to 
# return a different ldap attribute. This different attribute is ideally one that 
# exists in your environment. 


require 'ruby-jss'

cred = {
        server: "casperjss.education.edu",
        port: 8443,
        user: "apiuser",
        pw: :prompt
}

JSS.api.connect cred

# create a list of computers and their groups.
def make_computer_list
        comp_list = []
        JSS::Computer.all_objects.each {|c|
                comp_list.push({id: c.id, user: c.location[:username], groups: c.static_groups.values.flatten})
        }
        return comp_list
end


# create a list of groups that already exist
# so we don't make them again
def make_existing_groups_list
        exist_group_list = []
        JSS::ComputerGroup.all_static.map {|g| exist_group_list.push(g[:name])}
        return exist_group_list
end

# method for checking ldap to see a user's affiliation
def check_person_type(user)
        `ldapsearch -x -H ldaps://ldap-blue.ucsc.edu -b ou=People,dc=ucsc,dc=edu uid=#{user} | grep "ucscPersonPubAffiliation:"`.split(" ")[1]
end


# add ldap results to cache
def add_ldap_to_computer_list(comp_list)
        comp_list.each {|c|
                c[:type] = check_person_type(c[:user])
        }
        return comp_list
end

# make a list of the names of the groups that we'll be adding computers to
def list_found_groups(comp_list)
        comp_list.each {|c|
                found_groups.push(c[:type])
        }
        return found_groups.uniq!.compact!
end

# create missing groups
def create_missing_groups(found_groups)
        groups_to_be_made = []
        found_groups.delete_if {|g| g =~ /(#{existing_groups.join("|")})/}
        found_groups.size.times {|g|
                groups_to_be_made[g] = JSS::ComputerGroup.make name: found_groups[g], type: :static
        }
        groups_to_be_made.each {|g| g.save}
end


# add computers to groups
# c[:type] matches a group
def turn_group_names_into_objects(found_groups)
        found_groups.map! {|g|
                JSS::ComputerGroup.fetch name: g
        }
        return found_groups
end

# in order to add members to each group, we need to create arrays of
# the ids that should be in each group. After that, we call the .members
# method in order to add the computers as an array of ids.
# after that, we save the object

def add_computers_to_groups(group_objs, comp_list)
        group_objs.each {|g|
                comp_ids = comp_list.select {|c| c[:type] == g.name}.map {|y| y[:id]}
                if g.members.map {|m| m[:id]}.sort == comp_ids.sort
                        return
                else
                        g.members = comp_ids
                        g.save
                end
        }
end


def make_groups_and_assign_computers
        comp_list = add_ldap_to_computer_list(make_computer_list)
        existing_groups = make_existing_groups_list
        found_groups = list_found_groups(comp_list)
        create_missing_groups(found_groups)
        group_objs = turn_group_names_into_objects(found_groups)
        add_computers_to_groups(group_objs, comp_list)
end

make_groups_and_assign_computers
