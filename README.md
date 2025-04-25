# WalmartCountries
Coding challenge for Walmart

For the assignment I utilized programmatic UI code for creating each UI element. The ViewController.swift file contains all of the necessary functionality to handle the assigned task. There are three different collection objects that manage the different requirements- all countries, displayed countries and filtered countries. The application properly displays either displayed countries or filtered countries depending on if the search text field has any input. The countries are pulled from the link utilizing URLSession.shared.dataTask and memory is properly managed with weak references. 
