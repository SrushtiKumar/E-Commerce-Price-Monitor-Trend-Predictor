import os
import requests
from bs4 import BeautifulSoup
import re
import pandas as pd
import time

# Script-relative paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")

def scrape_page(page_num):
    """
    Scrapes a single page of the webscraper.io scroll test site.
    Returns a list of dictionaries with cleaned product data.
    """
    url = f"https://webscraper.io/test-sites/scroll?page={page_num}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            print(f"Warning: Failed to fetch page {page_num} (Status code: {response.status_code})")
            return []
    except Exception as e:
        print(f"Error fetching page {page_num}: {e}")
        return []
        
    soup = BeautifulSoup(response.text, "html.parser")
    cards = soup.find_all("div", class_="test-sites-card")
    
    products = []
    for card in cards:
        try:
            # 1. Title and URL
            title_tag = card.find("h3", class_="card-title")
            if not title_tag:
                continue
            title = title_tag.text.strip()
            link_tag = title_tag.find("a")
            product_url = link_tag["href"] if link_tag else ""
            if product_url and not product_url.startswith("http"):
                product_url = f"https://webscraper.io{product_url}"
                
            # 2. Description
            desc_tag = card.find("p", class_="description")
            description = desc_tag.text.strip() if desc_tag else ""
            
            # 3. Year, Country, Mileage
            year, country, mileage = None, "", None
            card_texts = card.find_all("p", class_="card-text")
            for p in card_texts:
                text = p.text.strip()
                if "Year:" in text:
                    val = text.replace("Year:", "").strip()
                    try:
                        year = int(val)
                    except ValueError:
                        pass
                elif "Country of origin:" in text:
                    country = text.replace("Country of origin:", "").strip()
                elif "Mileage:" in text:
                    val = text.replace("Mileage:", "").replace("km", "").strip()
                    val = re.sub(r"\s+", "", val) # Remove all spacing
                    try:
                        mileage = int(val)
                    except ValueError:
                        pass
            
            # 4. Rating (extracted from data-rating attribute)
            rating_div = card.find("div", class_="rarity-rating")
            rating = None
            if rating_div and rating_div.has_attr("data-rating"):
                try:
                    rating = int(rating_div["data-rating"])
                except ValueError:
                    pass
            
            # 5. Price (clean EUR currency symbol and whitespaces)
            price_tag = card.find("p", class_="price")
            price = None
            if price_tag:
                price_text = price_tag.text.strip()
                price_num_str = re.sub(r"[^\d]", "", price_text)
                try:
                    price = float(price_num_str)
                except ValueError:
                    pass
            
            # 6. Availability
            availability_tag = card.find("div", class_="availability")
            availability = 0
            if availability_tag:
                avail_text = availability_tag.text.strip().lower()
                if "available" in avail_text:
                    avail_num = re.sub(r"[^\d]", "", avail_text)
                    try:
                        availability = int(avail_num)
                    except ValueError:
                        availability = 1
                else:
                    # Sold or Reserved counts as 0 availability
                    availability = 0
                    
            # 7. Brand (First word of the title)
            brand = title.split()[0] if title else "Unknown"
            
            products.append({
                "Title": title,
                "Brand": brand,
                "Description": description,
                "Year": year,
                "Country": country,
                "Mileage_km": mileage,
                "Rating": rating,
                "Price_EUR": price,
                "Availability": availability,
                "URL": product_url
            })
        except Exception as card_error:
            print(f"Error parsing card: {card_error}")
            
    return products

def get_total_pages():
    """
    Fetches the first page and parses the total page count from the container's data-last-page attribute.
    Defaults to 17 if parsing fails.
    """
    url = "https://webscraper.io/test-sites/scroll"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, "html.parser")
            container = soup.find("div", class_="test-items-container")
            if container and container.has_attr("data-last-page"):
                return int(container["data-last-page"])
    except Exception as e:
        print(f"Error checking last page: {e}")
    return 17  # Fallback to known page count

def scrape_and_save():
    """
    Scrapes all pages and saves the cleaned dataset to base_scraped_cars.csv.
    """
    max_pages = get_total_pages()
    print(f"Total pages detected: {max_pages}")
    
    all_products = []
    print(f"Starting scraper for webscraper.io scroll test site...")
    for p in range(1, max_pages + 1):
        print(f"Scraping page {p}/{max_pages}...")
        page_products = scrape_page(p)
        if not page_products:
            print(f"No products found on page {p}. Stopping scraper.")
            break
        all_products.extend(page_products)
        # Sleep slightly to be polite to the server
        time.sleep(0.3)
        
    df = pd.DataFrame(all_products)
    if not df.empty:
        os.makedirs(DATA_DIR, exist_ok=True)
        csv_path = os.path.join(DATA_DIR, "scraped_cars.csv")
        df.to_csv(csv_path, index=False)
        print(f"\nSuccess! Scraped {len(df)} vehicles and saved to: {csv_path}")
    else:
        print("Error: No data scraped.")
    return df

if __name__ == "__main__":
    scrape_and_save()
