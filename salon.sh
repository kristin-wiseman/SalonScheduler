#!/bin/bash
# "Salon Appointment Booker" Project by Kristin Wiseman

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~ Salon Appointment Booker ~~~\n"

MAIN_MENU() {
  if [[ $1 ]]; then echo -e "\n$1"; fi
  echo -e "Services Available:"

  # get available services, display with formatting
  AVAILABLE_SERVICES=$($PSQL "SELECT * FROM services;")
  echo "$AVAILABLE_SERVICES" | while read S_ID BAR NAME
  do
    echo "$S_ID) $NAME"
  done

  read SERVICE_ID_SELECTED
  # Should always return result b/c I added NOT NULL constraint to name column.
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;" | sed "s/ *//g")

  if [[ -z $SERVICE_NAME ]]; then
    MAIN_MENU "That service isn't available. Please pick a service from the list."
  else
    # ask for a phone number
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';" | sed "s/ *//g")

    # if new customer
    if [[ -z $CUSTOMER_NAME ]]; then
      # get customer's name
      echo -e "\nThere's no customer with that phone number. What's your name?"
      read CUSTOMER_NAME
      # add to customers table
      ADD_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME');")
    fi

    echo -e "\nWhat time would you like for your $SERVICE_NAME, $CUSTOMER_NAME?"
    read SERVICE_TIME

    # Find customer ID to make appointment
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
    MAKE_APPT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")

    # I chose to add error handling to the confirmation message.
    if [[ $MAKE_APPT_RESULT == "INSERT 0 1" ]]; then
      echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME.\n"
    else
      # Return to main menu with error.
      MAIN_MENU "\nThere was a problem making that appointment. Please try again.\n"
    fi
  fi

}

MAIN_MENU
