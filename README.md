Problem
=======

Sales Reps have open opportunities and need to change the price book, such as to use latest prices. Salesforce standard behavior is to delete all existing line items when an opportunity's price book changes. Therein lies the problem, the Sales Reps don't want to rekey all their data and Management wants everyone using the newer price books.

Solution
========

1. Create a flow that automates re-creating all the line items on the opportunity to reference the same products from the new price book entries while preserving the user-entered unit price, quantity, and line description.
2. Create a visualforce page for [launching the flow](https://www.salesforce.com/us/developer/docs/pages/Content/pages_flows_adding.htm) and overriding the standard "Choose Price Book" behavior of the button on the Opportunity Products related list.

![screenshot](/images/flow.png)

![screenshot](/images/page.png)

![screenshot](/images/override_choose_pricebook_button.png)

Requirements
============

This solution requires new Flow elements offered in the [Spring '14 "Flow Trigger Pilot"](http://docs.releasenotes.salesforce.com/en-us/spring14/release-notes/rn_forcecom_process_flow_action.htm). Please contact Salesforce Support if you are not yet participating in the Pilot Program.

Deployment: How To
==================

To simplify deployment of this custom code to your org, you may use the [github deploy tool](http://andyinthecloud.com/2013/09/24/deploy-direct-from-github-to-salesforce/) developed by [Andy Fawcett](https://twitter.com/andyinthecloud).

Once deployed, you will need to grant users access to the page as well as override the standard "Choose Price Book" action on the Opportunity Product object (Setup | Customize | Opportunities | Opportunity Products | Buttons and Links)

To deploy in your **sandbox**:
https://githubsfdeploy-sandbox.herokuapp.com/app/githubdeploy/douglascayers/sfdc-change-opportunity-pricebook-flow

To deploy to **production**:
https://githubsfdeploy.herokuapp.com/app/githubdeploy/douglascayers/sfdc-change-opportunity-pricebook-flow

*If deploying to production via github tool fails due to tests not being run, you may opt to use Change Sets or Ant Tool or however you normally deploy your code from sandbox to production. Please use your best judgement and due diligence before making any production changes to your org.*
