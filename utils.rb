module Utils
    def self.add_socialgroups(database, socialgroup_ids, contact_id, user)
        socialgroups = database.execute("SELECT * FROM socialgroups WHERE user_id IS ? AND id IN (#{(['?']*socialgroup_ids.length).join(",")})", user[0].to_i, socialgroup_ids)
        socialgroup_contact_relation = socialgroups.map { |s| [contact_id,s[0]] }
        socialgroup_contact_relation_extracted = []
        socialgroup_contact_relation.each do |relation|
            socialgroup_contact_relation_extracted += relation
        end
        if socialgroup_contact_relation.length > 0
            database.execute("INSERT INTO contact_socialgroups(contact_id, socialgroup_id) VALUES #{(["(?,?)"]*socialgroup_contact_relation.length).join(",")}", socialgroup_contact_relation);     
        end
    end
end