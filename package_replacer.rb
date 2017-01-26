#!/usr/bin/ruby
# author cosmo martinez
# cosmo@ucsc.edu
# 
# INSTRUCTIONS
# 
# Finds policies with an old package, removes the old package
# from those policies and adds the new one in its place.
# 
# Fill out the credentials section and the
# old_pkg_id and new_pkg_id then run.

require 'jss'


# enter your credentials here
JSS::API.connect(
  :user => 'user',
  :pw => 'password',
  :server => 'jss.blah.edu',
  :port => 8443
)

# enter the package you are trying to replace and the
# package that you want to replace it with
old_pkg_id = 26
new_pkg_id = 70
 
# do not edit below this line
# policy lookup
policy_list = JSS::Policy.all_objects

for policy in policy_list
  for i in policy.package_ids
    if i == old_pkg_id
      policy_obj = JSS::Policy.new :id => policy.id
      policy_obj.remove_package(old_pkg_id)
      policy_obj.add_package(new_pkg_id)
      policy_obj.update
    end
  end
end
