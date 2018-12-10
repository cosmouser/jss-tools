require 'ruby-jss'
cred = {
  server: ENV["JSS_SERVER"],
  port: ENV["JSS_PORT"].to_i,
  user: ENV["JSS_API_USER"],
  pw: ENV["JSS_API_PW"]
}
JSS.api.connect cred


# Find orphan computer groups.
# Orphan computer groups are computer groups that are not
# attached to any policies, restricted software or 
# configuration profiles

allNames = JSS::ComputerGroup.all_names
usedNames = []
scrapeScope = Proc.new do |obj| 
	if !obj.scopable?
		return
	end
	scope = obj.scope
	scope.inclusions[:computer_groups].each do |grp|
		if usedNames.include?(grp) == false 
			usedNames.push(grp)
		end
	end
	scope.exclusions[:computer_groups].each do |grp|
		if usedNames.include?(grp) == false 
			usedNames.push(grp)
		end
	end
end


JSS::Policy.all_objects.each do |obj|
	scrapeScope.call(obj)
end
JSS::OSXConfigurationProfile.all_objects.each do |obj|
	scrapeScope.call(obj)
end
JSS::RestrictedSoftware.all_objects.each do |obj|
	scrapeScope.call(obj)
end
allNames = allNames - ["All Managed Clients", "All Managed Servers"]
pp allNames - usedNames

