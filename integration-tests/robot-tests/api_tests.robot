*** Settings ***
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem

*** Variables ***
@{products}       0PUK6V6EV0  1YMWWN1N4O  2ZYFJ3GM2N  66VCHSJNUP  6E92ZMYYFZ  9SIQT8TOJO  L9ECAV7KIM  LS4PSXUNUM  OLJCESPC7Z
${load}           10
${mdns}           Get Environment Variable    machine_dns
${BASE_URL}       ${mdns}

*** Test Cases ***
Load Test
    ${threads}=    Create List
    FOR    ${i}    IN RANGE    ${load}
        ${mdns}=    Set Machine DNS
        ${thread}=    Run Keyword    Test Session    ${mdns}
        Append To List    ${threads}    ${thread}
    END
    FOR    ${thread}    IN    @{threads}
        Wait Until Keyword Succeeds    2s    10ms    ${thread}

Test Session
    [Arguments]    ${mdns}
    ${order}=    Create List    Test Index    Test Set Currency    Test Browse Product    Test Add To Cart    Test View Cart    Test Add To Cart    Test Checkout
    ${session}=    Create Session    ${BASE_URL}
    FOR    ${o}    IN    @{order}
        Run Keyword    ${o}    ${session}

Test Bad Requests
    ${response}=    GET On Session    ${session}    ${BASE_URL}/product/89
    Should Be Equal As Strings    ${response.status_code}    500
    ${data}=    Create Dictionary    currency_code    not a currency
    ${response}=    POST On Session    ${session}    ${BASE_URL}/setCurrency    data=${data}
    Should Be Equal As Strings    ${response.status_code}    500

Test Index
    ${response}=    GET On Session    ${session}    ${BASE_URL}/
    Should Be Equal As Strings    ${response.status_code}    200

Test Set Currency
    ${currencies}=    Create List    EUR    USD    JPY    CAD
    FOR    ${currency}    IN    @{currencies}
        ${data}=    Create Dictionary    currency_code    ${currency}
        ${response}=    POST On Session    ${session}    ${BASE_URL}/setCurrency    data=${data}
        Should Be Equal As Strings    ${response.status_code}    200
    ${data}=    Create Dictionary    currency_code    ${random.choice(['EUR', 'USD', 'JPY', 'CAD'])}
    ${response}=    POST On Session    ${session}    ${BASE_URL}/setCurrency    data=${data}

Test Browse Product
    FOR    ${product_id}    IN    @{products}
        ${response}=    GET On Session    ${session}    ${BASE_URL}/product/${product_id}
        Should Be Equal As Strings    ${response.status_code}    200

Test View Cart
    ${response}=    GET On Session    ${session}    ${BASE_URL}/cart
    Should Be Equal As Strings    ${response.status_code}    200
    ${response}=    POST On Session    ${session}    ${BASE_URL}/cart/empty
    Should Be Equal As Strings    ${response.status_code}    200

Test Add To Cart
    FOR    ${product_id}    IN    @{products}
        ${response}=    GET On Session    ${session}    ${BASE_URL}/product/${product_id}
        Should Be Equal As Strings    ${response.status_code}    200
        ${data}=    Create Dictionary    product_id    ${product_id}    quantity    ${random.choice([1, 2, 3, 4, 5, 10])}
        ${response}=    POST On Session    ${session}    ${BASE_URL}/cart    data=${data}
        Should Be Equal As Strings    ${response.status_code}    200

Test Checkout
    ${data}=    Create Dictionary    email    someone@example.com    street_address    1600 Amphitheatre Parkway    zip_code    94043    city    Mountain View    state    CA    country    United States    credit_card_number    4432-8015-6152-0454    credit_card_expiration_month    1    credit_card_expiration_year    2039    credit_card_cvv    672
    FOR    ${product_id}    IN    @{products}
        ${response}=    POST On Session    ${session}    ${BASE_URL}/cart/checkout    data=${data}
        Should Be Equal As Strings    ${response.status_code}    200

*** Keywords ***
Set Machine DNS
    [Return]    ${mdns}
    ${mdns}=    Get Environment Variable    machine_dns
