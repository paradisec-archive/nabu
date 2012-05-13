# Nabu Catalog



# Ruby help

plugins/gems/bundles:
 gem -v
 bundle update
 bundle install

Installing ruby:
  rbenv install [TAB][TAB] 
  rbenv install 1.9.3-XXX
  rbenv global 1.9.3-XXX
  gem install bundler --no-ri --no-rdoc

DB setup:
 rake db:drop
 rake db:create
 rake db:migrate

Importing old PARADISEC data:
 rake import:all

Running solr:
 rake sunspot:solr:start

After import:
 rake sunspot:reindex

Running the app:
 script/rails s

test:
 rake cucumber:wip
 bundle exec cucumber --profile wip
 rake cucumber:ok
 bundle exec cucumber features/xxx

DB load:
 rake db:schema:load
 APP_ENV=test rake db:schema:load

after commit local:
 cap deploy
 cap -T


# ANDS

RDA harvests data in RIF-CS, an XML based format.

For getting started:

- [Publishing Data](http://ands.org.au/publishing/index.html)
- [Comprehensive reference](http://ands.org.au/guides/content-providers-guide.html)

The important thing to understand about RIF-CS is that RDA collects and exposes
information at the *collection* level, not at the level of individual objects.
PARADISEC is somewhat unique in already having a strong notion of a "collection"
of items, so the export of metadata is relatively straightforward.

Probably the most useful thing for you is the Java source code for the
export I wrote last time, which I have attached. It was written for a
previous version of our API, and indeed a previous version of the
RIF-CS schema[1], so would probably need some minor updates to run.

[Java API](http://ands.org.au/resource/java-api.html)

I didn't do a formal crosswalk, but I think the source code is relatively
readable. If you're developing in Java, you'll probably want to use the API, and
reuse parts of the code.

Now, assuming that your new database has all the same information as the old
one, then yes I'd expect you could make a feed with records at least as good as
what I came up with previously. You might also consider:

1. Providing Activity records, if you're able to associate material
with the projects/grants that led to it being collected
1. Using NLA party identifiers. We now have integration with the NLA's
party infrastructure (ie, Trove), so rather than providing thin
records like
http://services.ands.org.au/home/orca/rda/view.php?key=paradisec.org.au%2F80,
you can link to the NLA party identifier instead:
http://nla.gov.au/nla.party-783591

This is explained here:
http://ands.org.au/resource/ardc-party-infrastructure-1.0.pdf

1. We now automatically calculate reverse links (eg, linking from a
Collection to a Party automatically links back as well), so some of
the code can be simplified.


