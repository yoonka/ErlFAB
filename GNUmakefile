.DEFAULT_GOAL := all

# Erlang Rebar downloading, see: https://groups.google.com/forum/?fromgroups=#!topic/erlang-programming/U0JJ3SeUv5Y
REBAR=$(shell which rebar || echo ./rebar)
REBAR_URL=http://cloud.github.com/downloads/basho/rebar/rebar

./rebar:
	$(ERL) -noshell -s inets -s ssl \
	  -eval 'httpc:request(get, {"$(REBAR_URL)", []}, [], [{stream, "./rebar"}])' \
	  -s init stop
	chmod +x ./rebar

all: $(REBAR)
	$(REBAR) compile
	erl -pa ebin -run erlfab -noshell -s init stop
