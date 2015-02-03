Expo Morning Pull
This is the main reporting query from my Data Deputy role in AR. It created a number of useful base-tables, and a summary that was built to feed an Google Docs report, into which it exported.

The thing I'm most proud of with this query is the structure afforded by the timeperiod column. This made it so, with a little work done beforehand, equality joins could be made on a single column reference (using it as a key), instead of long inequality relations between various date columns and the current date. By imposing on each row the label "Today", or "Week to Date", or "Next Weekend", etc, I was able to ease the computational burden on the machine running the query and on queries based off the tables.

Key sections are:
EventAttendees:
lns 37 - 94
This is meant to collect and organize in a single table, the information in the three tables VAN puts its event data in. The table then shows a single row for each volunteer*event*shift, with columns for:
the date on which that shift was recruited;
what the current status of the shift was;
whether that shift had ever been marked as {Scheduled, Confirmed, Completed} (which determined whether we would count it as a flaked shift or not);
whether, specifically, that shift had ever been marked "confirmed";
whether, at the time the shift was completed, the attendee was a fellow;
along with more basic information.

EventSummary:
lns 174 - 215
This assembled the data from EventAttendees (along with the basetables at 106-125 and 131-164) into a table with easily aggregable columns. It takes advantage of the work done in 131-164 to avoid nasty case statements or joins for the sake of grouping data by time-windows, and of the modular scheme (completed shifts are 1 (mod 2) and closed shifts are 1 (mod 3)) set up at lines 45-47.



Elegant AfAm Reapportionment
 This query was meant to address a large discrepancy in undecided voters between African American voters and all other voters in the AG race. African American voters were undecided by a good 10 or so more points.
We wanted to examine the hypothetical, by media market, of what the overall AG race would look like if those African American voters were only undecided at the rate all other voters were.

To separate out the undecided block, and be able to maintain propotionality, I used two properties.

1) The sum of weights apportioned to a candidate in a group is equal to the percentage of that group apportioned to that candidate multiplied by the total weight of that group.
So letting w_a_h be the combined weight of AfAm Herring respondents, w_a be the combined weight of AfAm respondents, and h_a be the percentage (by weight) of AfAm respondents who support Herring:
w_a_h=h_a * w_a
as h_a = w_a_h / (w_a_h + w_a_o + w_a_u) = w_a_h / w_a

2) The percentage of Herring or Obenshain support in a three way contest is equal to the support in a two way contest, multiplied by one minus the percentage of respondents undecided
Letting h_i be the percentage Herring respondents, o_i be percentage Obenshain respondents, and u_a be percentage undecided respondents, in demographic group i,
h_i = sum(w_i_h)/sum(w_i_[h,o,u])
h_i + o_i + u_i = 1

h_i = [h_i/(h_i+o_i)]*(1-u_i)  <= h_i / (1- u_i) = h_i / (h_i + o_i)
where one can note that the quantity in square brackets [] is the two way split for Herring.

This makes is possible, having the two way and three way splits, to very simply change the undecided percentage in any particular group, and examine the effect on the entire population.
Since that number is typically calculated by summing the weights of x supporters, divided by the weights of all respondents, we simply split the weights as in line 8, represent the percentages for African Americans
as on line 16, then replace the undecided % u_a with the undecided % in the rest of the population, u_~a. This keeps all the relevant constraints in place.

Samuel Roberts